-- Deploy: schemas/organizers/tables/organizers/triggers/set_updated_at
-- made with <3 @ constructive.io

-- requires: schemas/organizers/tables/organizers
-- requires: common:schemas/common/functions/set_updated_at

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON organizers.organizers
  FOR EACH ROW
  EXECUTE FUNCTION common.set_updated_at();
