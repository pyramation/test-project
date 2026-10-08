-- Verify: schemas/events/tables/events/indexes/events_venue_id_idx

DO $$
BEGIN
  PERFORM 1 FROM pg_indexes WHERE schemaname = 'events' AND indexname = 'events_venue_id_idx';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Index events.events_venue_id_idx does not exist';
  END IF;
END $$;
