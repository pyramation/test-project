-- Revert: schemas/tickets/tables/tickets/triggers/set_updated_at

DROP TRIGGER IF EXISTS set_updated_at ON tickets.tickets;
