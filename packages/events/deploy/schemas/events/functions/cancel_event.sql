-- Deploy: schemas/events/functions/cancel_event
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/events

CREATE FUNCTION events.cancel_event(event_id uuid)
RETURNS events.events AS $$
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
$$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION events.cancel_event(uuid) IS
  'Cancels a draft or published event. Raises if the event is missing or already cancelled.';
