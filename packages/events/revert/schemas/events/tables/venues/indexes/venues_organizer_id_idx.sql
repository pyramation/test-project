-- Revert: schemas/events/tables/venues/indexes/venues_organizer_id_idx

DROP INDEX IF EXISTS events.venues_organizer_id_idx;
