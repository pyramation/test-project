-- Verify: schemas/common/functions/set_updated_at

SELECT has_function_privilege('common.set_updated_at()', 'execute');
