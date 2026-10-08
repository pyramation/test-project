-- Verify: schemas/tickets/tables/attendees

SELECT id, email, name, created_at, updated_at
FROM tickets.attendees
WHERE FALSE;
