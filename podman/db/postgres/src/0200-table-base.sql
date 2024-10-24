CREATE TABLE IF NOT EXISTS tables.base(
   relid       BIGSERIAL
  ,id          VARCHAR(11)              GENERATED ALWAYS AS (code.RELID_TO_ID(relid)) STORED              
  ,tbloid      OID                      NOT NULL
  ,version     INTEGER                  DEFAULT 1
  ,description TEXT
  ,terms       TSVECTOR
  ,extra       JSONB
  ,created     TIMESTAMP WITH TIME ZONE
  ,modified    TIMESTAMP WITH TIME ZONE
);

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
CREATE INDEX IF NOT EXISTS global_ix_terms ON tables.base USING GIN(terms);

-- Index on extra field for json key value comparisons
CREATE INDEX IF NOT EXISTS global_ix_extra ON tables.base USING GIN(extra JSONB_PATH_OPS);

-- Index on created field for created date comparisons
CREATE INDEX IF NOT EXISTS global_ix_created ON tables.base (created);

-- Index on modified field for modified date comparisons
CREATE INDEX IF NOT EXISTS global_ix_modified ON tables.base (modified);

-- NEXT_BASE gets the next relid by inserting an entry into base
-- P_TBL is the table oid of the table to insert into
-- P_DESC is the description
-- P_TERMS is the terms
-- P_EXTRA is the extra
-- Returns all columns of the new row
--
-- Invoke by using a statement like SELECT code.NEXT_BASE('tables.country'::regclass::oid);
CREATE OR REPLACE FUNCTION code.NEXT_BASE(P_TBL OID, P_DESC TEXT = NULL, P_TERMS TEXT = NULL, P_EXTRA JSONB = NULL) RETURNS tables.base AS
$$
  INSERT INTO tables.base(
             tbloid
             ,version
             ,description
             ,terms
             ,extra
             ,created
             ,modified
           )
    VALUES (
              P_TBL
             ,1
             ,P_DESC
             ,TO_TSVECTOR('english', P_TERMS)
             ,P_EXTRA
             ,NOW() AT TIME ZONE 'UTC'
             ,NOW() AT TIME ZONE 'UTC'
           )
 RETURNING *;
$$ LANGUAGE sql;
