-- Deploy: schemas/tickets/functions/reserve_ticket
-- made with <3 @ constructive.io

-- requires: schemas/tickets/functions/tickets_remaining
-- requires: events:schemas/events/tables/events

CREATE FUNCTION tickets.reserve_ticket(
  ticket_type_id uuid,
  attendee_email text,
  attendee_name text
)
RETURNS tickets.tickets AS $$
DECLARE
  tt tickets.ticket_types;
  ev events.events;
  att tickets.attendees;
  result tickets.tickets;
BEGIN
  -- Lock the ticket type so concurrent reservations serialize on the capacity check.
  SELECT * INTO tt
  FROM tickets.ticket_types t
  WHERE t.id = reserve_ticket.ticket_type_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ticket type % not found', ticket_type_id USING ERRCODE = 'no_data_found';
  END IF;

  SELECT * INTO ev FROM events.events e WHERE e.id = tt.event_id;

  IF ev.status <> 'published' THEN
    RAISE EXCEPTION 'event % is not open for ticket sales', ev.id USING ERRCODE = 'check_violation';
  END IF;

  IF tt.sales_start_at IS NOT NULL AND now() < tt.sales_start_at THEN
    RAISE EXCEPTION 'ticket sales for % have not started', tt.name USING ERRCODE = 'check_violation';
  END IF;

  IF tt.sales_end_at IS NOT NULL AND now() > tt.sales_end_at THEN
    RAISE EXCEPTION 'ticket sales for % have ended', tt.name USING ERRCODE = 'check_violation';
  END IF;

  IF tickets.tickets_remaining(tt.id) <= 0 THEN
    RAISE EXCEPTION 'ticket type % is sold out', tt.name USING ERRCODE = 'check_violation';
  END IF;

  INSERT INTO tickets.attendees (email, name)
  VALUES (lower(attendee_email), attendee_name)
  ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name
  RETURNING * INTO att;

  INSERT INTO tickets.tickets (ticket_type_id, attendee_id)
  VALUES (tt.id, att.id)
  RETURNING * INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION tickets.reserve_ticket(uuid, text, text) IS
  'Reserves one seat of a ticket type for an attendee (created or updated by email). Raises when the event is not published, sales are closed, or the type is sold out.';
