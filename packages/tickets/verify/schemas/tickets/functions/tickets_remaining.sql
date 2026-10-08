-- Verify: schemas/tickets/functions/tickets_remaining

SELECT has_function_privilege('tickets.tickets_remaining(uuid)', 'execute');
