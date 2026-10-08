-- Verify: schemas/events/tables/events/indexes/events_starts_at_idx

DO $$
BEGIN
  PERFORM 1 FROM pg_indexes WHERE schemaname = 'events' AND indexname = 'events_starts_at_idx';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Index events.events_starts_at_idx does not exist';
  END IF;
END $$;
