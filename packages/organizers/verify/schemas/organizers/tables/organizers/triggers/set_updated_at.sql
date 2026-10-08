-- Verify: schemas/organizers/tables/organizers/triggers/set_updated_at

DO $$
BEGIN
  PERFORM 1
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE t.tgname = 'set_updated_at'
    AND n.nspname = 'organizers'
    AND c.relname = 'organizers';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trigger set_updated_at on organizers.organizers does not exist';
  END IF;
END $$;
