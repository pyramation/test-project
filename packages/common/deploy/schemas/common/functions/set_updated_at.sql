-- Deploy: schemas/common/functions/set_updated_at
-- made with <3 @ constructive.io

-- requires: schemas/common

CREATE FUNCTION common.set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION common.set_updated_at() IS
  'BEFORE UPDATE trigger function: stamps updated_at with the transaction time.';
