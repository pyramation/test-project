-- Deploy: schemas/events/tables/events/indexes/events_starts_at_idx
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/events

CREATE INDEX events_starts_at_idx ON events.events (starts_at) WHERE status = 'published';

COMMENT ON INDEX events.events_starts_at_idx IS 'Serves the upcoming_events view: published events ordered by start time.';
