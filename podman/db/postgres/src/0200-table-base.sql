CREATE TABLE IF NOT EXISTS global(
   relid       BIGINT                   NOT NULL
  ,version     INTEGER                  NOT NULL
  ,description TEXT
  ,terms       TSVECTOR
  ,extra       JSONB
  ,created     TIMESTAMP WITH TIME ZONE NOT NULL
  ,modified    TIMESTAMP WITH TIME ZONE NOT NULL
);

-- Sequence for relids
CREATE SEQUENCE IF NOT EXISTS global_relid_seq AS BIGINT;

-- Index on base descriptor field for full text searches
CREATE INDEX IF NOT EXISTS global_ix_terms ON base USING GIN(terms);

-- Index on extra field for json key value comparisons
CREATE INDEX IF NOT EXISTS global_ix_extra ON base USING GIN(extra JSONB_PATH_OPS);

-- Index on created field for created date comparisons
CREATE INDEX IF NOT EXISTS global_ix_created ON base (created);

-- Index on created field for modified date comparisons
CREATE INDEX IF NOT EXISTS global_ix_modified ON base (modified);
