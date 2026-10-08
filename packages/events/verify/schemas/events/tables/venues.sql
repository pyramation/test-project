-- Verify: schemas/events/tables/venues

SELECT id, organizer_id, name, address, city, country, capacity, created_at, updated_at
FROM events.venues
WHERE FALSE;
