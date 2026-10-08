\echo Use "CREATE EXTENSION common" to load this file. \quit
CREATE SCHEMA common;

COMMENT ON SCHEMA common IS 'Shared helper functions used by every events-platform module.';

CREATE FUNCTION common.set_updated_at() RETURNS trigger AS $EOFCODE$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$EOFCODE$ LANGUAGE plpgsql;

COMMENT ON FUNCTION common.set_updated_at() IS 'BEFORE UPDATE trigger function: stamps updated_at with the transaction time.';

CREATE FUNCTION common.slugify(
  input text
) RETURNS text AS $EOFCODE$
  SELECT trim(both '-' from regexp_replace(lower(input), '[^a-z0-9]+', '-', 'g'));
$EOFCODE$ LANGUAGE sql IMMUTABLE STRICT PARALLEL safe;

COMMENT ON FUNCTION common.slugify(text) IS 'Lower-cases the input and collapses every run of non-alphanumeric characters into a single hyphen.';