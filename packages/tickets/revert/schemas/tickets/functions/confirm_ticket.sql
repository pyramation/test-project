-- Revert: schemas/tickets/functions/confirm_ticket

DROP FUNCTION IF EXISTS tickets.confirm_ticket(uuid);
