-- Deploy: schemas/common/functions/slugify
-- made with <3 @ constructive.io

-- requires: schemas/common

CREATE FUNCTION common.slugify(input text)
RETURNS text AS $$
  SELECT trim(both '-' from regexp_replace(lower(input), '[^a-z0-9]+', '-', 'g'));
$$ LANGUAGE sql IMMUTABLE STRICT PARALLEL SAFE;

COMMENT ON FUNCTION common.slugify(text) IS
  'Lower-cases the input and collapses every run of non-alphanumeric characters into a single hyphen.';
