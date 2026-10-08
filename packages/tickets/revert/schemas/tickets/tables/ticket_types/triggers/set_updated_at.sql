-- Revert: schemas/tickets/tables/ticket_types/triggers/set_updated_at

DROP TRIGGER IF EXISTS set_updated_at ON tickets.ticket_types;
