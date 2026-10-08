-- Deploy: schemas/tickets/tables/tickets/indexes/tickets_ticket_type_id_idx
-- made with <3 @ constructive.io

-- requires: schemas/tickets/tables/tickets

CREATE INDEX tickets_ticket_type_id_idx ON tickets.tickets (ticket_type_id);
