-- ====================
-- ==== base table ====
-- ====================
CREATE TABLE IF NOT EXISTS tables.base(
   relid       BIGSERIAL
  ,version     INTEGER
  ,description TEXT
  ,terms       TSVECTOR
  ,extra       JSONB
  ,created     TIMESTAMP WITH TIME ZONE
  ,modified    TIMESTAMP WITH TIME ZONE
);

-- Primary key
SELECT 'ALTER TABLE tables.base ADD CONSTRAINT base_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'base'
      AND CONSTRAINT_NAME = 'base_pk'
 )
\gexec

-- Index on base descriptor field for full text searches
CREATE INDEX IF NOT EXISTS base_ix_terms    ON tables.base USING GIN(terms);

-- Index on extra field for json key value comparisons
CREATE INDEX IF NOT EXISTS base_ix_extra    ON tables.base USING GIN(extra JSONB_PATH_OPS);

-- Index on created field for created date comparisons
CREATE INDEX IF NOT EXISTS base_ix_created  ON tables.base (created);

-- Index on modified field for modified date comparisons
CREATE INDEX IF NOT EXISTS base_ix_modified ON tables.base (modified);

-- Row trigger function to ensure that:
-- - relid comes from sequence and is never modified 
-- - version increments sequentially starting at 1
-- - created is inserted as current timestamp, and never updated
-- - modified is always current timestamp
--
-- NOTES:
-- - current timestamp is not an immutable function, so cannot be used for a generated column
-- - this trigger must be separately applied to each child table
-- - it is not applied to the base table, as that would not accomplish anything
CREATE OR REPLACE FUNCTION base_tg_modified_row_fn() RETURNS trigger AS
$$
DECLARE
  V_CT TIMESTAMP := NOW() AT TIME ZONE 'UTC';
BEGIN
  CASE TG_OP
    WHEN 'INSERT' THEN
      NEW.version  = 1;
      NEW.created  = V_CT;
      NEW.modified = V_CT;
  
    WHEN 'UPDATE' THEN
      NEW.version  = OLD.version + 1;
      NEW.modified = V_CT;
        
    ELSE NULL;
  END CASE;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
