-- Verify: schemas/tickets/functions/cancel_ticket

SELECT has_function_privilege('tickets.cancel_ticket(uuid)', 'execute');
