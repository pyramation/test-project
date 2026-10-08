-- Verify: schemas/events

DO $$
BEGIN
  PERFORM 1 FROM information_schema.schemata WHERE schema_name = 'events';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Schema events does not exist';
  END IF;
END $$;
