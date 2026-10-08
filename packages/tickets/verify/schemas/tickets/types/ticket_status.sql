-- Verify: schemas/tickets/types/ticket_status

DO $$
BEGIN
  PERFORM 1
  FROM pg_type t
  JOIN pg_namespace n ON n.oid = t.typnamespace
  WHERE n.nspname = 'tickets' AND t.typname = 'ticket_status' AND t.typtype = 'e';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Type tickets.ticket_status does not exist';
  END IF;
END $$;
