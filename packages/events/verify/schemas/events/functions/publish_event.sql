-- Verify: schemas/events/functions/publish_event

SELECT has_function_privilege('events.publish_event(uuid)', 'execute');
