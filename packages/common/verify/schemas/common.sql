-- Verify: schemas/common

DO $$
BEGIN
  PERFORM 1 FROM information_schema.schemata WHERE schema_name = 'common';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Schema common does not exist';
  END IF;
END $$;
