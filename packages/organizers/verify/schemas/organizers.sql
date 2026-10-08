-- Verify: schemas/organizers

DO $$
BEGIN
  PERFORM 1 FROM information_schema.schemata WHERE schema_name = 'organizers';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Schema organizers does not exist';
  END IF;
END $$;
