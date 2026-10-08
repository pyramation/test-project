-- Verify: schemas/tickets/functions/reserve_ticket

SELECT has_function_privilege('tickets.reserve_ticket(uuid, text, text)', 'execute');
