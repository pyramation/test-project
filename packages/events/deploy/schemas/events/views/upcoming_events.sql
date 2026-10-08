-- Deploy: schemas/events/views/upcoming_events
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/events

CREATE VIEW events.upcoming_events
  WITH (security_invoker = true)
AS
  SELECT e.id, e.organizer_id, e.venue_id, e.title, e.slug, e.description,
         e.starts_at, e.ends_at, e.capacity
  FROM events.events e
  WHERE e.status = 'published'
    AND e.starts_at >= now()
  ORDER BY e.starts_at;

COMMENT ON VIEW events.upcoming_events IS 'Published events that have not started yet, soonest first.';
