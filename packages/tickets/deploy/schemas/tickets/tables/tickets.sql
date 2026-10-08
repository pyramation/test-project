-- Deploy: schemas/tickets/tables/tickets
-- made with <3 @ constructive.io

-- requires: schemas/tickets/types/ticket_status
-- requires: schemas/tickets/tables/ticket_types
-- requires: schemas/tickets/tables/attendees

CREATE TABLE tickets.tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_type_id uuid NOT NULL REFERENCES tickets.ticket_types(id) ON DELETE CASCADE,
  attendee_id uuid NOT NULL REFERENCES tickets.attendees(id) ON DELETE CASCADE,
  status tickets.ticket_status NOT NULL DEFAULT 'reserved',
  reserved_at timestamptz NOT NULL DEFAULT now(),
  confirmed_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE tickets.tickets IS 'One seat of a ticket type held by an attendee.';
COMMENT ON COLUMN tickets.tickets.status IS 'reserved on creation; confirmed after payment; cancelled frees the seat.';
