-- Verify: schemas/tickets/tables/ticket_types

SELECT id, event_id, name, price_cents, currency, quantity, sales_start_at, sales_end_at, created_at, updated_at
FROM tickets.ticket_types
WHERE FALSE;
