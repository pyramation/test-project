-- Revert: schemas/events/functions/publish_event

DROP FUNCTION IF EXISTS events.publish_event(uuid);
