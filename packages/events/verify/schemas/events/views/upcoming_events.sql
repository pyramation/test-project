-- Verify: schemas/events/views/upcoming_events

SELECT id, organizer_id, venue_id, title, slug, description, starts_at, ends_at, capacity
FROM events.upcoming_events
WHERE FALSE;
