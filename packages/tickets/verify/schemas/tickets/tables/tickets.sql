-- Verify: schemas/tickets/tables/tickets

SELECT id, ticket_type_id, attendee_id, status, reserved_at, confirmed_at, cancelled_at, created_at, updated_at
FROM tickets.tickets
WHERE FALSE;
