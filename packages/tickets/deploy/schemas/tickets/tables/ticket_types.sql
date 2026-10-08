-- Deploy: schemas/tickets/tables/ticket_types
-- made with <3 @ constructive.io

-- requires: schemas/tickets
-- requires: events:schemas/events/tables/events

CREATE TABLE tickets.ticket_types (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id uuid NOT NULL REFERENCES events.events(id) ON DELETE CASCADE,
  name text NOT NULL CHECK (length(name) > 0),
  price_cents integer NOT NULL DEFAULT 0 CHECK (price_cents >= 0),
  currency text NOT NULL DEFAULT 'USD' CHECK (currency ~ '^[A-Z]{3}$'),
  quantity integer NOT NULL CHECK (quantity > 0),
  sales_start_at timestamptz,
  sales_end_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ticket_types_event_id_name_key UNIQUE (event_id, name),
  CONSTRAINT ticket_types_sales_window CHECK (
    sales_start_at IS NULL OR sales_end_at IS NULL OR sales_end_at > sales_start_at
  )
);

COMMENT ON TABLE tickets.ticket_types IS 'A class of ticket for an event (e.g. General Admission, VIP) with a fixed quantity.';
COMMENT ON COLUMN tickets.ticket_types.price_cents IS 'Price in the smallest unit of currency; 0 for free tickets.';
COMMENT ON COLUMN tickets.ticket_types.quantity IS 'Total number of tickets that can be sold for this type.';
COMMENT ON CONSTRAINT ticket_types_event_id_name_key ON tickets.ticket_types IS 'Also serves as the covering index for event_id lookups.';
