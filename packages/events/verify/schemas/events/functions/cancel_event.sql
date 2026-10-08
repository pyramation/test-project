-- Verify: schemas/events/functions/cancel_event

SELECT has_function_privilege('events.cancel_event(uuid)', 'execute');
