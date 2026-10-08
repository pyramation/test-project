-- Verify: schemas/events/tables/venues/indexes/venues_organizer_id_idx

DO $$
BEGIN
  PERFORM 1 FROM pg_indexes WHERE schemaname = 'events' AND indexname = 'venues_organizer_id_idx';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Index events.venues_organizer_id_idx does not exist';
  END IF;
END $$;
