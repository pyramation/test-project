-- Revert: schemas/events/tables/events/triggers/set_updated_at

DROP TRIGGER IF EXISTS set_updated_at ON events.events;
