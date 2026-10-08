import { getConnections, PgTestClient } from 'pgsql-test';

let pg: PgTestClient;
let teardown: () => Promise<void>;

beforeAll(async () => {
  ({ pg, teardown } = await getConnections());
});

afterAll(async () => {
  await teardown();
});

beforeEach(async () => {
  await pg.beforeEach();
});

afterEach(async () => {
  await pg.afterEach();
});

const insertOrganizer = (slug = 'acme-events', name = 'Acme Events') =>
  pg.query(
    `INSERT INTO organizers.organizers (name, slug, email, website)
     VALUES ($1, $2, 'hello@acme.example', 'https://acme.example')
     RETURNING *`,
    [name, slug]
  );

describe('organizers.organizers', () => {
  it('creates an organizer with generated id and timestamps', async () => {
    const { rows } = await insertOrganizer();
    expect(rows[0].id).toMatch(/^[0-9a-f-]{36}$/);
    expect(rows[0].name).toBe('Acme Events');
    expect(rows[0].slug).toBe('acme-events');
    expect(rows[0].created_at).toBeInstanceOf(Date);
    expect(rows[0].updated_at).toBeInstanceOf(Date);
  });

  it('rejects a duplicate slug', async () => {
    await insertOrganizer('acme-events');
    await expect(insertOrganizer('acme-events', 'Another Acme')).rejects.toThrow(/duplicate key/);
  });

  it('rejects a slug that is not url-safe', async () => {
    await expect(insertOrganizer('Not A Slug')).rejects.toThrow(/violates check constraint/);
  });

  it('rejects an invalid email', async () => {
    await expect(
      pg.query(`INSERT INTO organizers.organizers (name, slug, email) VALUES ('X', 'x', 'not-an-email')`)
    ).rejects.toThrow(/violates check constraint/);
  });

  it('bumps updated_at on update', async () => {
    const { rows } = await pg.query(`
      INSERT INTO organizers.organizers (name, slug, email, updated_at)
      VALUES ('Old', 'old', 'old@example.com', now() - interval '1 day')
      RETURNING id, created_at, updated_at
    `);
    const { id, updated_at: before } = rows[0];

    await pg.query(`UPDATE organizers.organizers SET name = 'New' WHERE id = $1`, [id]);
    const after = (await pg.query(`SELECT name, updated_at FROM organizers.organizers WHERE id = $1`, [id])).rows[0];

    expect(after.name).toBe('New');
    expect(after.updated_at.getTime()).toBeGreaterThan(before.getTime());
  });
});
