-- Verify: schemas/events/types/event_status

DO $$
BEGIN
  PERFORM 1
  FROM pg_type t
  JOIN pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = 'events' AND t.typname = 'event_status' AND t.typtype = 'e';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Type events.event_status does not exist';
  END IF;
END $$;
