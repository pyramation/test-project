-- Deploy: schemas/events/tables/events/indexes/events_venue_id_idx
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/events

CREATE INDEX events_venue_id_idx ON events.events (venue_id);
