-- Verify: schemas/tickets/functions/confirm_ticket

SELECT has_function_privilege('tickets.confirm_ticket(uuid)', 'execute');
