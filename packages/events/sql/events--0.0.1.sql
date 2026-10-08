\echo Use "CREATE EXTENSION events" to load this file. \quit
CREATE SCHEMA events;

COMMENT ON SCHEMA events IS 'Events, their venues, and scheduling.';

CREATE TYPE events.event_status AS ENUM ('draft', 'published', 'cancelled');

COMMENT ON TYPE events.event_status IS 'Lifecycle of an event: draft -> published -> cancelled.';

CREATE TABLE events.venues (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id uuid NOT NULL REFERENCES organizers.organizers (id)
    ON DELETE CASCADE,
  name text NOT NULL CHECK (length(name) > 0),
  address text,
  city text,
  country text,
  capacity int CHECK (capacity > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE events.venues IS 'A physical location an organizer can host events at.';

COMMENT ON COLUMN events.venues.capacity IS 'Maximum number of attendees the venue can hold, if known.';

CREATE INDEX venues_organizer_id_idx ON events.venues (organizer_id);

CREATE TRIGGER set_updated_at
  BEFORE UPDATE
  ON events.venues
  FOR EACH ROW
  EXECUTE PROCEDURE common.set_updated_at();

CREATE TABLE events.events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id uuid NOT NULL REFERENCES organizers.organizers (id)
    ON DELETE CASCADE,
  venue_id uuid REFERENCES events.venues (id)
    ON DELETE SET NULL,
  title text NOT NULL CHECK (length(title) > 0),
  slug text NOT NULL CHECK (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'),
  description text,
  status events.event_status NOT NULL DEFAULT 'draft',
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  capacity int CHECK (capacity > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT events_ends_after_starts 
    CHECK (ends_at > starts_at),
  CONSTRAINT events_organizer_id_slug_key 
    UNIQUE (organizer_id, slug)
);

COMMENT ON TABLE events.events IS 'A scheduled event hosted by an organizer, optionally at a venue.';

COMMENT ON COLUMN events.events.slug IS 'URL-safe identifier, unique per organizer. Derived from the title when omitted.';

COMMENT ON COLUMN events.events.status IS 'draft until published; cancelled events keep their history.';

COMMENT ON COLUMN events.events.capacity IS 'Overall attendee cap for the event, independent of ticket quantities.';

COMMENT ON CONSTRAINT events_organizer_id_slug_key ON events.events IS 'Also serves as the covering index for organizer_id lookups.';

CREATE INDEX events_venue_id_idx ON events.events (venue_id);

CREATE INDEX events_starts_at_idx ON events.events (starts_at) WHERE status = 'published';

COMMENT ON INDEX events.events_starts_at_idx IS 'Serves the upcoming_events view: published events ordered by start time.';

CREATE TRIGGER set_updated_at
  BEFORE UPDATE
  ON events.events
  FOR EACH ROW
  EXECUTE PROCEDURE common.set_updated_at();

CREATE FUNCTION events.tg_events_set_slug() RETURNS trigger AS $EOFCODE$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := common.slugify(NEW.title);
  END IF;
  RETURN NEW;
END;
$EOFCODE$ LANGUAGE plpgsql;

COMMENT ON FUNCTION events.tg_events_set_slug() IS 'BEFORE INSERT trigger function: derives slug from title when the caller omits it.';

CREATE TRIGGER set_slug
  BEFORE INSERT
  ON events.events
  FOR EACH ROW
  EXECUTE PROCEDURE events.tg_events_set_slug();

CREATE FUNCTION events.publish_event(
  event_id uuid
) RETURNS events.events AS $EOFCODE$
DECLARE
  result events.events;
BEGIN
  UPDATE events.events e
     SET status = 'published'
   WHERE e.id = publish_event.event_id
     AND e.status = 'draft'
  RETURNING e.* INTO result;

  IF result.id IS NULL THEN
    IF NOT EXISTS (SELECT 1 FROM events.events e WHERE e.id = publish_event.event_id) THEN
      RAISE EXCEPTION 'event % not found', event_id USING ERRCODE = 'no_data_found';
    END IF;
    RAISE EXCEPTION 'event % is not a draft and cannot be published', event_id
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN result;
END;
$EOFCODE$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION events.publish_event(uuid) IS 'Moves a draft event to published. Raises if the event is missing or not a draft.';

CREATE FUNCTION events.cancel_event(
  event_id uuid
) RETURNS events.events AS $EOFCODE$
DECLARE
  result events.events;
BEGIN
  UPDATE events.events e
     SET status = 'cancelled'
   WHERE e.id = cancel_event.event_id
     AND e.status <> 'cancelled'
  RETURNING e.* INTO result;

  IF result.id IS NULL THEN
    IF NOT EXISTS (SELECT 1 FROM events.events e WHERE e.id = cancel_event.event_id) THEN
      RAISE EXCEPTION 'event % not found', event_id USING ERRCODE = 'no_data_found';
    END IF;
    RAISE EXCEPTION 'event % is already cancelled', event_id USING ERRCODE = 'check_violation';
  END IF;

  RETURN result;
END;
$EOFCODE$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION events.cancel_event(uuid) IS 'Cancels a draft or published event. Raises if the event is missing or already cancelled.';

CREATE VIEW events.upcoming_events WITH (security_invoker = 'true') AS SELECT
  e.id,
  e.organizer_id,
  e.venue_id,
  e.title,
  e.slug,
  e.description,
  e.starts_at,
  e.ends_at,
  e.capacity
FROM events.events AS e
WHERE
  e.status = 'published'
  AND e.starts_at >= now()
ORDER BY
  e.starts_at;

COMMENT ON VIEW events.upcoming_events IS 'Published events that have not started yet, soonest first.';