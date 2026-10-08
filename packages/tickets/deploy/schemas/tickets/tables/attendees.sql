-- Deploy: schemas/tickets/tables/attendees
-- made with <3 @ constructive.io

-- requires: schemas/tickets

CREATE TABLE tickets.attendees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE CHECK (email = lower(email) AND email ~ '^[^@[:space:]]+@[^@[:space:]]+$'),
  name text NOT NULL CHECK (length(name) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE tickets.attendees IS 'A person who holds tickets, identified by lower-cased email.';
