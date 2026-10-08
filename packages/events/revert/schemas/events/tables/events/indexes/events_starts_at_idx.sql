-- Revert: schemas/events/tables/events/indexes/events_starts_at_idx

DROP INDEX IF EXISTS events.events_starts_at_idx;
