-- Revert: schemas/events/tables/events/indexes/events_venue_id_idx

DROP INDEX IF EXISTS events.events_venue_id_idx;
