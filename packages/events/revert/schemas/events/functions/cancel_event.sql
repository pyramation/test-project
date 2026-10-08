-- Revert: schemas/events/functions/cancel_event

DROP FUNCTION IF EXISTS events.cancel_event(uuid);
