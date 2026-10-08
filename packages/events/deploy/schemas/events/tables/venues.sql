-- Deploy: schemas/events/tables/venues
-- made with <3 @ constructive.io

-- requires: schemas/events
-- requires: organizers:schemas/organizers/tables/organizers

CREATE TABLE events.venues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id uuid NOT NULL REFERENCES organizers.organizers(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (length(name) > 0),
  address text,
  city text,
  country text,
  capacity integer CHECK (capacity > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE events.venues IS 'A physical location an organizer can host events at.';
COMMENT ON COLUMN events.venues.capacity IS 'Maximum number of attendees the venue can hold, if known.';
