-- Deploy: schemas/events/tables/events
-- made with <3 @ constructive.io

-- requires: schemas/events/types/event_status
-- requires: schemas/events/tables/venues

CREATE TABLE events.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id uuid NOT NULL REFERENCES organizers.organizers(id) ON DELETE CASCADE,
  venue_id uuid REFERENCES events.venues(id) ON DELETE SET NULL,
  title text NOT NULL CHECK (length(title) > 0),
  slug text NOT NULL CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text,
  status events.event_status NOT NULL DEFAULT 'draft',
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  capacity integer CHECK (capacity > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT events_ends_after_starts CHECK (ends_at > starts_at),
  CONSTRAINT events_organizer_id_slug_key UNIQUE (organizer_id, slug)
);

COMMENT ON TABLE events.events IS 'A scheduled event hosted by an organizer, optionally at a venue.';
COMMENT ON COLUMN events.events.slug IS 'URL-safe identifier, unique per organizer. Derived from the title when omitted.';
COMMENT ON COLUMN events.events.status IS 'draft until published; cancelled events keep their history.';
COMMENT ON COLUMN events.events.capacity IS 'Overall attendee cap for the event, independent of ticket quantities.';
COMMENT ON CONSTRAINT events_organizer_id_slug_key ON events.events IS 'Also serves as the covering index for organizer_id lookups.';
