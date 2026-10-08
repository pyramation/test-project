-- Deploy: schemas/events/functions/publish_event
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/events

CREATE FUNCTION events.publish_event(event_id uuid)
RETURNS events.events AS $$
DECLARE
  result events.events;
BEGIN
  UPDATE events.events e
     SET status = 'published'
   WHERE e.id = publish_event.event_id
     AND e.status = 'draft'
  RETURNING e.* INTO result;

  IF result.id IS NULL THEN
    IF NOT EXISTS (SELECT 1 FROM events.events e WHERE e.id = publish_event.event_id) THEN
      RAISE EXCEPTION 'event % not found', event_id USING ERRCODE = 'no_data_found';
    END IF;
    RAISE EXCEPTION 'event % is not a draft and cannot be published', event_id
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION events.publish_event(uuid) IS
  'Moves a draft event to published. Raises if the event is missing or not a draft.';
