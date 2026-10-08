-- Deploy: schemas/tickets/functions/tickets_remaining
-- made with <3 @ constructive.io

-- requires: schemas/tickets/tables/tickets

CREATE FUNCTION tickets.tickets_remaining(ticket_type_id uuid)
RETURNS integer AS $$
  SELECT tt.quantity - (
    SELECT count(*)
    FROM tickets.tickets t
    WHERE t.ticket_type_id = tt.id
      AND t.status <> 'cancelled'
  )::integer
  FROM tickets.ticket_types tt
  WHERE tt.id = tickets_remaining.ticket_type_id;
$$ LANGUAGE sql STABLE STRICT;

COMMENT ON FUNCTION tickets.tickets_remaining(uuid) IS
  'Seats still available for a ticket type: quantity minus reserved and confirmed tickets. NULL for an unknown id.';
