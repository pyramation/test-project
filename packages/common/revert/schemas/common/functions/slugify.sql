-- Revert: schemas/common/functions/slugify

DROP FUNCTION IF EXISTS common.slugify(text);
