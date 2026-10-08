import { getConnections, PgTestClient } from 'pgsql-test';

let pg: PgTestClient;
let teardown: () => Promise<void>;
let eventId: string;
let ticketTypeId: string;

beforeAll(async () => {
  ({ pg, teardown } = await getConnections());
});

afterAll(async () => {
  await teardown();
});

beforeEach(async () => {
  await pg.beforeEach();

  const organizer = await pg.query(`
    INSERT INTO organizers.organizers (name, slug, email)
    VALUES ('Acme Events', 'acme-events', 'hello@acme.example')
    RETURNING id
  `);
  const event = await pg.query(
    `INSERT INTO events.events (organizer_id, title, starts_at, ends_at)
     VALUES ($1, 'PostgreSQL Meetup', now() + interval '7 days', now() + interval '7 days 2 hours')
     RETURNING id`,
    [organizer.rows[0].id]
  );
  eventId = event.rows[0].id;
  await pg.query(`SELECT events.publish_event($1)`, [eventId]);

  const ticketType = await pg.query(
    `INSERT INTO tickets.ticket_types (event_id, name, price_cents, quantity)
     VALUES ($1, 'General Admission', 2500, 2)
     RETURNING id`,
    [eventId]
  );
  ticketTypeId = ticketType.rows[0].id;
});

afterEach(async () => {
  await pg.afterEach();
});

// A failed statement aborts the surrounding test transaction, so expected
// failures run inside their own savepoint and roll back to it afterwards.
const expectQueryToFail = async (sql: string, params: unknown[], message: RegExp) => {
  await pg.query('SAVEPOINT expected_failure');
  await expect(pg.query(sql, params)).rejects.toThrow(message);
  await pg.query('ROLLBACK TO SAVEPOINT expected_failure');
};

const reserve = (email: string, name = 'Test Attendee', typeId = ticketTypeId) =>
  pg.query(`SELECT * FROM tickets.reserve_ticket($1, $2, $3)`, [typeId, email, name]);

const remaining = async (typeId = ticketTypeId) =>
  (await pg.query(`SELECT tickets.tickets_remaining($1) AS n`, [typeId])).rows[0].n;

describe('tickets.reserve_ticket', () => {
  it('reserves a seat and creates the attendee', async () => {
    expect(await remaining()).toBe(2);

    const { rows } = await reserve('Ada@Example.com', 'Ada Lovelace');
    expect(rows[0].status).toBe('reserved');
    expect(rows[0].ticket_type_id).toBe(ticketTypeId);

    const attendee = await pg.query(`SELECT * FROM tickets.attendees WHERE id = $1`, [rows[0].attendee_id]);
    expect(attendee.rows[0].email).toBe('ada@example.com');
    expect(attendee.rows[0].name).toBe('Ada Lovelace');
    expect(await remaining()).toBe(1);
  });

  it('reuses an attendee by email across reservations', async () => {
    const first = await reserve('ada@example.com', 'Ada');
    const second = await reserve('ADA@example.com', 'Ada L.');
    expect(second.rows[0].attendee_id).toBe(first.rows[0].attendee_id);

    const attendees = await pg.query(`SELECT count(*)::int AS n, min(name) AS name FROM tickets.attendees`);
    expect(attendees.rows[0]).toEqual({ n: 1, name: 'Ada L.' });
  });

  it('refuses to oversell a ticket type', async () => {
    await reserve('a@example.com');
    await reserve('b@example.com');
    expect(await remaining()).toBe(0);
    await expect(reserve('c@example.com')).rejects.toThrow(/sold out/);
  });

  it('refuses reservations for an event that is not published', async () => {
    await pg.query(`SELECT events.cancel_event($1)`, [eventId]);
    await expect(reserve('a@example.com')).rejects.toThrow(/not open for ticket sales/);
  });

  it('honours the sales window', async () => {
    const closed = await pg.query(
      `INSERT INTO tickets.ticket_types (event_id, name, quantity, sales_start_at, sales_end_at)
       VALUES ($1, 'Early Bird', 10, now() - interval '2 days', now() - interval '1 day')
       RETURNING id`,
      [eventId]
    );
    await expectQueryToFail(
      `SELECT tickets.reserve_ticket($1, 'a@example.com', 'A')`,
      [closed.rows[0].id],
      /have ended/
    );

    const future = await pg.query(
      `INSERT INTO tickets.ticket_types (event_id, name, quantity, sales_start_at)
       VALUES ($1, 'Late Release', 10, now() + interval '1 day')
       RETURNING id`,
      [eventId]
    );
    await expect(reserve('a@example.com', 'A', future.rows[0].id)).rejects.toThrow(/have not started/);
  });

  it('raises for an unknown ticket type', async () => {
    await expect(reserve('a@example.com', 'A', '00000000-0000-0000-0000-000000000000')).rejects.toThrow(/not found/);
  });
});

describe('tickets.confirm_ticket / tickets.cancel_ticket', () => {
  it('confirms a reserved ticket once', async () => {
    const { rows } = await reserve('a@example.com');
    const confirmed = await pg.query(`SELECT * FROM tickets.confirm_ticket($1)`, [rows[0].id]);
    expect(confirmed.rows[0].status).toBe('confirmed');
    expect(confirmed.rows[0].confirmed_at).toBeInstanceOf(Date);

    await expect(pg.query(`SELECT tickets.confirm_ticket($1)`, [rows[0].id])).rejects.toThrow(/not reserved/);
  });

  it('cancelling a ticket frees its seat', async () => {
    const first = await reserve('a@example.com');
    await reserve('b@example.com');
    expect(await remaining()).toBe(0);

    const cancelled = await pg.query(`SELECT * FROM tickets.cancel_ticket($1)`, [first.rows[0].id]);
    expect(cancelled.rows[0].status).toBe('cancelled');
    expect(await remaining()).toBe(1);

    const again = await reserve('c@example.com');
    expect(again.rows[0].status).toBe('reserved');
    await expect(pg.query(`SELECT tickets.cancel_ticket($1)`, [first.rows[0].id])).rejects.toThrow(/already cancelled/);
  });

  it('returns null remaining for an unknown ticket type', async () => {
    expect(await remaining('00000000-0000-0000-0000-000000000000')).toBeNull();
  });
});

describe('tickets.ticket_types', () => {
  it('rejects duplicate names within an event', async () => {
    await expect(
      pg.query(`INSERT INTO tickets.ticket_types (event_id, name, quantity) VALUES ($1, 'General Admission', 5)`, [eventId])
    ).rejects.toThrow(/ticket_types_event_id_name_key/);
  });

  it('cascades when the event is deleted', async () => {
    await reserve('a@example.com');
    await pg.query(`DELETE FROM events.events WHERE id = $1`, [eventId]);
    const left = await pg.query(`SELECT count(*)::int AS n FROM tickets.tickets`);
    expect(left.rows[0].n).toBe(0);
  });
});
