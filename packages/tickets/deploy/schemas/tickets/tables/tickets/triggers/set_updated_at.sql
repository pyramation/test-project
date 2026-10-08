-- Deploy: schemas/tickets/tables/tickets/triggers/set_updated_at
-- made with <3 @ constructive.io

-- requires: schemas/tickets/tables/tickets
-- requires: common:schemas/common/functions/set_updated_at

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON tickets.tickets
  FOR EACH ROW
  EXECUTE FUNCTION common.set_updated_at();
