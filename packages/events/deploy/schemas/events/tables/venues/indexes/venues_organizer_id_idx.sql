-- Deploy: schemas/events/tables/venues/indexes/venues_organizer_id_idx
-- made with <3 @ constructive.io

-- requires: schemas/events/tables/venues

CREATE INDEX venues_organizer_id_idx ON events.venues (organizer_id);
