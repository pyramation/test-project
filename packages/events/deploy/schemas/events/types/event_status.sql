-- Deploy: schemas/events/types/event_status
-- made with <3 @ constructive.io

-- requires: schemas/events

CREATE TYPE events.event_status AS ENUM ('draft', 'published', 'cancelled');

COMMENT ON TYPE events.event_status IS 'Lifecycle of an event: draft -> published -> cancelled.';
