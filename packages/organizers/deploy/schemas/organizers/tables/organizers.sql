-- Deploy: schemas/organizers/tables/organizers
-- made with <3 @ constructive.io

-- requires: schemas/organizers

CREATE TABLE organizers.organizers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL CHECK (length(name) > 0),
  slug text NOT NULL UNIQUE CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  email text NOT NULL CHECK (email ~ '^[^@[:space:]]+@[^@[:space:]]+$'),
  website text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE organizers.organizers IS 'An organization or person that hosts events.';
COMMENT ON COLUMN organizers.organizers.slug IS 'URL-safe unique identifier (lower-case, hyphen separated).';
COMMENT ON COLUMN organizers.organizers.email IS 'Primary contact address for the organizer.';
