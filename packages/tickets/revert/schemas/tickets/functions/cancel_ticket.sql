-- Revert: schemas/tickets/functions/cancel_ticket

DROP FUNCTION IF EXISTS tickets.cancel_ticket(uuid);
