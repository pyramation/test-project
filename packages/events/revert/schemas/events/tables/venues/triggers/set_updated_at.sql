-- Revert: schemas/events/tables/venues/triggers/set_updated_at

DROP TRIGGER IF EXISTS set_updated_at ON events.venues;
