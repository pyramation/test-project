-- Deploy: schemas/events/tables/events/triggers/set_updated_at
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/events
-- requires: common:schemas/common/functions/set_updated_at

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON events.events
  FOR EACH ROW
  EXECUTE FUNCTION common.set_updated_at();
