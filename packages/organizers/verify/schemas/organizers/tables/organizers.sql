-- Verify: schemas/organizers/tables/organizers

SELECT id, name, slug, email, website, created_at, updated_at
FROM organizers.organizers
WHERE FALSE;
