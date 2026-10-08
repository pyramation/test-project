-- Revert: schemas/organizers/tables/organizers/triggers/set_updated_at

DROP TRIGGER IF EXISTS set_updated_at ON organizers.organizers;
