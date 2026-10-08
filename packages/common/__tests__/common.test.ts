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

describe('common.slugify', () => {
  it.each([
    ['Hello World', 'hello-world'],
    ['  PostgreSQL   Meetup!! 2026 ', 'postgresql-meetup-2026'],
    ['already-a-slug', 'already-a-slug'],
    ['Ünïcode & Symbols', 'n-code-symbols'],
    ['---', ''],
  ])('slugify(%p) -> %p', async (input, expected) => {
    const { rows } = await pg.query('SELECT common.slugify($1) AS slug', [input]);
    expect(rows[0].slug).toBe(expected);
  });

  it('returns null for null input', async () => {
    const { rows } = await pg.query('SELECT common.slugify(NULL) AS slug');
    expect(rows[0].slug).toBeNull();
  });
});

describe('common.set_updated_at', () => {
  it('stamps updated_at with the transaction time on update', async () => {
    await pg.query(`
      CREATE TEMP TABLE things (
        id serial PRIMARY KEY,
        name text NOT NULL,
        updated_at timestamptz NOT NULL DEFAULT now()
      )
    `);
    await pg.query(`
      CREATE TRIGGER set_updated_at
        BEFORE UPDATE ON things
        FOR EACH ROW EXECUTE FUNCTION common.set_updated_at()
    `);
    await pg.query(`INSERT INTO things (name, updated_at) VALUES ('a', now() - interval '1 day')`);

    const before = (await pg.query('SELECT updated_at FROM things')).rows[0].updated_at;
    await pg.query(`UPDATE things SET name = 'b'`);
    const after = (await pg.query('SELECT updated_at, name FROM things')).rows[0];

    expect(after.name).toBe('b');
    expect(new Date(after.updated_at).getTime()).toBeGreaterThan(new Date(before).getTime());
  });
});
