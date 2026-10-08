-- Deploy: schemas/events/tables/venues/triggers/set_updated_at
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/venues
-- requires: common:schemas/common/functions/set_updated_at

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON events.venues
  FOR EACH ROW
  EXECUTE FUNCTION common.set_updated_at();
