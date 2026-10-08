-- Verify: schemas/events/tables/events/triggers/set_slug

DO $$
BEGIN
  PERFORM 1
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE t.tgname = 'set_slug' AND n.nspname = 'events' AND c.relname = 'events';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trigger set_slug on events.events does not exist';
  END IF;
END $$;
