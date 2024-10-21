CREATE TABLE IF NOT EXISTS tables.base(
   relid       BIGSERIAL
  ,tbloid      OID                      NOT NULL
  ,version     INTEGER                  NOT NULL
  ,description TEXT
  ,terms       TSVECTOR
  ,extra       JSONB
  ,created     TIMESTAMP WITH TIME ZONE NOT NULL
  ,modified    TIMESTAMP WITH TIME ZONE NOT NULL
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
