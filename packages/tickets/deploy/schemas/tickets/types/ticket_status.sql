-- Deploy: schemas/tickets/types/ticket_status
-- made with <3 @ constructive.io

-- requires: schemas/tickets

CREATE TYPE tickets.ticket_status AS ENUM ('reserved', 'confirmed', 'cancelled');

COMMENT ON TYPE tickets.ticket_status IS 'Lifecycle of a ticket: reserved -> confirmed, or cancelled at any point.';
