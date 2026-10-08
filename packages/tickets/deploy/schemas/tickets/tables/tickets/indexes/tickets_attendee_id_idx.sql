-- Deploy: schemas/tickets/tables/tickets/indexes/tickets_attendee_id_idx
-- made with <3 @ constructive.io

-- requires: schemas/tickets/tables/tickets

CREATE INDEX tickets_attendee_id_idx ON tickets.tickets (attendee_id);
