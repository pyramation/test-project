-- Deploy: schemas/tickets/functions/cancel_ticket
-- made with <3 @ constructive.io

-- requires: schemas/tickets/tables/tickets

CREATE FUNCTION tickets.cancel_ticket(ticket_id uuid)
RETURNS tickets.tickets AS $$
DECLARE
  result tickets.tickets;
BEGIN
  UPDATE tickets.tickets t
     SET status = 'cancelled',
         cancelled_at = now()
   WHERE t.id = cancel_ticket.ticket_id
     AND t.status <> 'cancelled'
  RETURNING t.* INTO result;

  IF result.id IS NULL THEN
    IF NOT EXISTS (SELECT 1 FROM tickets.tickets t WHERE t.id = cancel_ticket.ticket_id) THEN
      RAISE EXCEPTION 'ticket % not found', ticket_id USING ERRCODE = 'no_data_found';
    END IF;
    RAISE EXCEPTION 'ticket % is already cancelled', ticket_id USING ERRCODE = 'check_violation';
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION tickets.cancel_ticket(uuid) IS
  'Cancels a reserved or confirmed ticket, freeing its seat. Raises if the ticket is missing or already cancelled.';
