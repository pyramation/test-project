import { getConnections, PgTestClient } from 'pgsql-test';

let pg: PgTestClient;
let teardown: () => Promise<void>;
let organizerId: string;

beforeAll(async () => {
  ({ pg, teardown } = await getConnections());
});

afterAll(async () => {
  await teardown();
});

beforeEach(async () => {
  await pg.beforeEach();
  const { rows } = await pg.query(`
    INSERT INTO organizers.organizers (name, slug, email)
    VALUES ('Acme Events', 'acme-events', 'hello@acme.example')
    RETURNING id
  `);
  organizerId = rows[0].id;
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

const insertEvent = (overrides: Record<string, unknown> = {}) => {
  const values = {
    organizer_id: organizerId,
    title: 'PostgreSQL Meetup',
    slug: null as string | null,
    starts_at: "now() + interval '7 days'",
    ends_at: "now() + interval '7 days 2 hours'",
    ...overrides,
  };
  return pg.query(
    `INSERT INTO events.events (organizer_id, title, slug, starts_at, ends_at)
     VALUES ($1, $2, $3, ${values.starts_at}, ${values.ends_at})
     RETURNING *`,
    [values.organizer_id, values.title, values.slug]
  );
};

describe('events.events', () => {
  it('derives the slug from the title when omitted', async () => {
    const { rows } = await insertEvent({ title: 'PostgreSQL Meetup: Spring 2026!' });
    expect(rows[0].slug).toBe('postgresql-meetup-spring-2026');
    expect(rows[0].status).toBe('draft');
  });

  it('keeps an explicit slug', async () => {
    const { rows } = await insertEvent({ slug: 'custom-slug' });
    expect(rows[0].slug).toBe('custom-slug');
  });

  it('rejects an event that ends before it starts', async () => {
    await expect(
      insertEvent({ starts_at: "now() + interval '2 hours'", ends_at: "now() + interval '1 hour'" })
    ).rejects.toThrow(/events_ends_after_starts/);
  });

  it('requires slugs to be unique per organizer only', async () => {
    await insertEvent({ slug: 'meetup' });
    await expectQueryToFail(
      `INSERT INTO events.events (organizer_id, title, slug, starts_at, ends_at)
       VALUES ($1, 'Dup', 'meetup', now() + interval '1 day', now() + interval '2 days')`,
      [organizerId],
      /events_organizer_id_slug_key/
    );

    const other = await pg.query(`
      INSERT INTO organizers.organizers (name, slug, email)
      VALUES ('Other', 'other', 'other@example.com') RETURNING id
    `);
    const { rows } = await insertEvent({ slug: 'meetup', organizer_id: other.rows[0].id });
    expect(rows[0].slug).toBe('meetup');
  });

  it('sets venue_id to null when the venue is deleted', async () => {
    const venue = await pg.query(
      `INSERT INTO events.venues (organizer_id, name, capacity) VALUES ($1, 'Main Hall', 200) RETURNING id`,
      [organizerId]
    );
    const { rows } = await insertEvent();
    await pg.query(`UPDATE events.events SET venue_id = $1 WHERE id = $2`, [venue.rows[0].id, rows[0].id]);
    await pg.query(`DELETE FROM events.venues WHERE id = $1`, [venue.rows[0].id]);

    const after = await pg.query(`SELECT venue_id FROM events.events WHERE id = $1`, [rows[0].id]);
    expect(after.rows[0].venue_id).toBeNull();
  });
});

describe('events.publish_event / events.cancel_event', () => {
  it('publishes a draft event', async () => {
    const { rows } = await insertEvent();
    const published = await pg.query(`SELECT * FROM events.publish_event($1)`, [rows[0].id]);
    expect(published.rows[0].status).toBe('published');
  });

  it('refuses to publish an event that is not a draft', async () => {
    const { rows } = await insertEvent();
    await pg.query(`SELECT events.publish_event($1)`, [rows[0].id]);
    await expect(pg.query(`SELECT events.publish_event($1)`, [rows[0].id])).rejects.toThrow(/not a draft/);
  });

  it('raises for an unknown event', async () => {
    await expect(
      pg.query(`SELECT events.publish_event('00000000-0000-0000-0000-000000000000')`)
    ).rejects.toThrow(/not found/);
  });

  it('cancels a published event and refuses to cancel it twice', async () => {
    const { rows } = await insertEvent();
    await pg.query(`SELECT events.publish_event($1)`, [rows[0].id]);
    const cancelled = await pg.query(`SELECT * FROM events.cancel_event($1)`, [rows[0].id]);
    expect(cancelled.rows[0].status).toBe('cancelled');
    await expect(pg.query(`SELECT events.cancel_event($1)`, [rows[0].id])).rejects.toThrow(/already cancelled/);
  });
});

describe('events.upcoming_events', () => {
  it('lists only published future events, soonest first', async () => {
    const later = await insertEvent({ slug: 'later', starts_at: "now() + interval '30 days'", ends_at: "now() + interval '31 days'" });
    const sooner = await insertEvent({ slug: 'sooner', starts_at: "now() + interval '1 day'", ends_at: "now() + interval '2 days'" });
    const past = await insertEvent({ slug: 'past', starts_at: "now() - interval '2 days'", ends_at: "now() - interval '1 day'" });
    await insertEvent({ slug: 'draft' });

    for (const ev of [later, sooner, past]) {
      await pg.query(`SELECT events.publish_event($1)`, [ev.rows[0].id]);
    }

    const { rows } = await pg.query(`SELECT slug FROM events.upcoming_events`);
    expect(rows.map((r) => r.slug)).toEqual(['sooner', 'later']);
  });
});
