-- Verify: schemas/tickets

DO $$
BEGIN
  PERFORM 1 FROM information_schema.schemata WHERE schema_name = 'tickets';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Schema tickets does not exist';
  END IF;
END $$;
