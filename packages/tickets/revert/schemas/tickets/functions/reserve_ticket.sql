-- Revert: schemas/tickets/functions/reserve_ticket

DROP FUNCTION IF EXISTS tickets.reserve_ticket(uuid, text, text);
