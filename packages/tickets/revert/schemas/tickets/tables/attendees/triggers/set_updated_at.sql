-- Revert: schemas/tickets/tables/attendees/triggers/set_updated_at

DROP TRIGGER IF EXISTS set_updated_at ON tickets.attendees;
