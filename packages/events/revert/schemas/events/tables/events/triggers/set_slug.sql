-- Revert: schemas/events/tables/events/triggers/set_slug

DROP TRIGGER IF EXISTS set_slug ON events.events;
DROP FUNCTION IF EXISTS events.tg_events_set_slug();
