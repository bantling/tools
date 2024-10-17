CREATE TABLE IF NOT EXISTS tables.base(
   relid       BIGINT                   NOT NULL
  ,version     INTEGER                  NOT NULL
  ,description TEXT
  ,terms       TSVECTOR
  ,extra       JSONB
  ,created     TIMESTAMP WITH TIME ZONE NOT NULL
  ,modified    TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Sequence for relids
CREATE SEQUENCE IF NOT EXISTS tables.global_relid_seq AS BIGINT;

-- Index on base descriptor field for full text searches
CREATE INDEX IF NOT EXISTS global_ix_terms ON tables.base USING GIN(terms);

-- Index on extra field for json key value comparisons
CREATE INDEX IF NOT EXISTS global_ix_extra ON tables.base USING GIN(extra JSONB_PATH_OPS);

-- Index on created field for created date comparisons
CREATE INDEX IF NOT EXISTS global_ix_created ON tables.base (created);

-- Index on created field for modified date comparisons
CREATE INDEX IF NOT EXISTS global_ix_modified ON tables.base (modified);

-- Generate next relid
-- Use this function instead of directly accessing above sequence, to provide flexibility to switch to another id scheme
CREATE OR REPLACE FUNCTION code.NEXT_RELID() RETURNS BIGINT AS
$$
BEGIN
  RETURN NEXTVAL('tables.global_relid_seq');
END;
$$ LANGUAGE plpgsql IMMUTABLE LEAKPROOF PARALLEL SAFE;

-- Test NEXT_RELID
DO $$
DECLARE
  V_LASTVAL BIGINT;
  V_RES BOOLEAN;
BEGIN
  SELECT last_value + code.IIF(is_called,1,0) FROM tables.global_relid_seq INTO V_LASTVAL;
  SELECT code.TEST('NEXT_RELID returns current value + 1', code.NEXT_RELID() = V_LASTVAL + 1) INTO V_RES;
  SELECT SETVAL('tables.global_relid_seq', V_LASTVAL) > 0 INTO V_RES;
  SELECT code.TEST('NEXT_RELID restored', CURRVAL('tables.global_relid_seq') = V_LASTVAL) INTO V_RES;
END;
$$ LANGUAGE plpgsql;
