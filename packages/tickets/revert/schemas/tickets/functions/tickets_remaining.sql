-- Revert: schemas/tickets/functions/tickets_remaining

DROP FUNCTION IF EXISTS tickets.tickets_remaining(uuid);
