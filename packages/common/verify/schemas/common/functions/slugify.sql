-- Verify: schemas/common/functions/slugify

SELECT has_function_privilege('common.slugify(text)', 'execute');
