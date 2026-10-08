\echo Use "CREATE EXTENSION tickets" to load this file. \quit
CREATE SCHEMA tickets;

COMMENT ON SCHEMA tickets IS 'Ticket types, attendees, and ticket reservations.';

CREATE TYPE tickets.ticket_status AS ENUM ('reserved', 'confirmed', 'cancelled');

COMMENT ON TYPE tickets.ticket_status IS 'Lifecycle of a ticket: reserved -> confirmed, or cancelled at any point.';

CREATE TABLE tickets.ticket_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events.events (id)
    ON DELETE CASCADE,
  name text NOT NULL CHECK (length(name) > 0),
  price_cents int NOT NULL DEFAULT 0 CHECK (price_cents >= 0),
  currency text NOT NULL DEFAULT 'USD' CHECK (currency ~ '^[A-Z]{3}$'),
  quantity int NOT NULL CHECK (quantity > 0),
  sales_start_at timestamptz,
  sales_end_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ticket_types_event_id_name_key 
    UNIQUE (event_id, name),
  CONSTRAINT ticket_types_sales_window 
    CHECK (
    sales_start_at IS NULL
      OR sales_end_at IS NULL
      OR sales_end_at > sales_start_at
  )
);

COMMENT ON TABLE tickets.ticket_types IS 'A class of ticket for an event (e.g. General Admission, VIP) with a fixed quantity.';

COMMENT ON COLUMN tickets.ticket_types.price_cents IS 'Price in the smallest unit of currency; 0 for free tickets.';

COMMENT ON COLUMN tickets.ticket_types.quantity IS 'Total number of tickets that can be sold for this type.';

COMMENT ON CONSTRAINT ticket_types_event_id_name_key ON tickets.ticket_types IS 'Also serves as the covering index for event_id lookups.';

CREATE TRIGGER set_updated_at
  BEFORE UPDATE
  ON tickets.ticket_types
  FOR EACH ROW
  EXECUTE PROCEDURE common.set_updated_at();

CREATE TABLE tickets.attendees (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE CHECK (
    email = lower(email)
      AND email ~ '^[^@[:space:]]+@[^@[:space:]]+$'
  ),
  name text NOT NULL CHECK (length(name) > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE tickets.attendees IS 'A person who holds tickets, identified by lower-cased email.';

CREATE TRIGGER set_updated_at
  BEFORE UPDATE
  ON tickets.attendees
  FOR EACH ROW
  EXECUTE PROCEDURE common.set_updated_at();

CREATE TABLE tickets.tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_type_id uuid NOT NULL REFERENCES tickets.ticket_types (id)
    ON DELETE CASCADE,
  attendee_id uuid NOT NULL REFERENCES tickets.attendees (id)
    ON DELETE CASCADE,
  status tickets.ticket_status NOT NULL DEFAULT 'reserved',
  reserved_at timestamptz NOT NULL DEFAULT now(),
  confirmed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE tickets.tickets IS 'One seat of a ticket type held by an attendee.';

COMMENT ON COLUMN tickets.tickets.status IS 'reserved on creation; confirmed after payment; cancelled frees the seat.';

CREATE INDEX tickets_ticket_type_id_idx ON tickets.tickets (ticket_type_id);

CREATE INDEX tickets_attendee_id_idx ON tickets.tickets (attendee_id);

CREATE TRIGGER set_updated_at
  BEFORE UPDATE
  ON tickets.tickets
  FOR EACH ROW
  EXECUTE PROCEDURE common.set_updated_at();

CREATE FUNCTION tickets.tickets_remaining(
  ticket_type_id uuid
) RETURNS int AS $EOFCODE$
  SELECT tt.quantity - (
    SELECT count(*)
    FROM tickets.tickets t
    WHERE t.ticket_type_id = tt.id
      AND t.status <> 'cancelled'
  )::integer
  FROM tickets.ticket_types tt
  WHERE tt.id = tickets_remaining.ticket_type_id;
$EOFCODE$ LANGUAGE sql STABLE STRICT;

COMMENT ON FUNCTION tickets.tickets_remaining(uuid) IS 'Seats still available for a ticket type: quantity minus reserved and confirmed tickets. NULL for an unknown id.';

CREATE FUNCTION tickets.reserve_ticket(
  ticket_type_id uuid,
  attendee_email text,
  attendee_name text
) RETURNS tickets.tickets AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION tickets.reserve_ticket(uuid, text, text) IS 'Reserves one seat of a ticket type for an attendee (created or updated by email). Raises when the event is not published, sales are closed, or the type is sold out.';

CREATE FUNCTION tickets.confirm_ticket(
  ticket_id uuid
) RETURNS tickets.tickets AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION tickets.confirm_ticket(uuid) IS 'Moves a reserved ticket to confirmed. Raises if the ticket is missing or not reserved.';

CREATE FUNCTION tickets.cancel_ticket(
  ticket_id uuid
) RETURNS tickets.tickets AS $EOFCODE$
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
$EOFCODE$ LANGUAGE plpgsql VOLATILE STRICT;

COMMENT ON FUNCTION tickets.cancel_ticket(uuid) IS 'Cancels a reserved or confirmed ticket, freeing its seat. Raises if the ticket is missing or already cancelled.';