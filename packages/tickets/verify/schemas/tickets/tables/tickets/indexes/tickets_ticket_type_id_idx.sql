-- Verify: schemas/tickets/tables/tickets/indexes/tickets_ticket_type_id_idx

DO $$
BEGIN
  PERFORM 1 FROM pg_indexes WHERE schemaname = 'tickets' AND indexname = 'tickets_ticket_type_id_idx';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Index tickets.tickets_ticket_type_id_idx does not exist';
  END IF;
END $$;
