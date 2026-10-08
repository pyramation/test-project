-- Deploy: schemas/events/tables/events/triggers/set_slug
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/events
-- requires: common:schemas/common/functions/slugify

CREATE FUNCTION events.tg_events_set_slug()
RETURNS trigger AS $$
BEGIN
  IF NEW.slug IS NULL OR NEW.slug = '' THEN
    NEW.slug := common.slugify(NEW.title);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION events.tg_events_set_slug() IS
  'BEFORE INSERT trigger function: derives slug from title when the caller omits it.';

CREATE TRIGGER set_slug
  BEFORE INSERT ON events.events
  FOR EACH ROW
  EXECUTE FUNCTION events.tg_events_set_slug();
