-- Deploy: schemas/tickets/tables/ticket_types/triggers/set_updated_at
-- made with <3 @ constructive.io

-- requires: schemas/tickets/tables/ticket_types
-- requires: common:schemas/common/functions/set_updated_at

CREATE TRIGGER set_updated_at
  BEFORE UPDATE ON tickets.ticket_types
  FOR EACH ROW
  EXECUTE FUNCTION common.set_updated_at();
