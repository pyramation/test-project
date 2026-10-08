-- Deploy: schemas/tickets/functions/confirm_ticket
-- made with <3 @ constructive.io

-- requires: schemas/tickets/tables/tickets

CREATE FUNCTION tickets.confirm_ticket(ticket_id uuid)
RETURNS tickets.tickets AS $$
DECLARE
  result tickets.tickets;
BEGIN
  UPDATE tickets.tickets t
     SET status = 'confirmed',
         confirmed_at = now()
   WHERE t.id = confirm_ticket.ticket_id
     AND t.status = 'reserved'
  RETURNING t.* INTO result;

  IF result.id IS NULL THEN
    IF NOT EXISTS (SELECT 1 FROM tickets.tickets t WHERE t.id = confirm_ticket.ticket_id) THEN
      RAISE EXCEPTION 'ticket % not found', ticket_id USING ERRCODE = 'no_data_found';
    END IF;
    RAISE EXCEPTION 'ticket % is not reserved and cannot be confirmed', ticket_id
      USING ERRCODE = 'check_violation';
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION tickets.confirm_ticket(uuid) IS
  'Moves a reserved ticket to confirmed. Raises if the ticket is missing or not reserved.';
