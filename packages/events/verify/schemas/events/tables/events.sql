-- Verify: schemas/events/tables/events

SELECT id, organizer_id, venue_id, title, slug, description, status,
       starts_at, ends_at, capacity, created_at, updated_at
FROM events.events
WHERE FALSE;
