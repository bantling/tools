-- Create country table
CREATE TABLE IF NOT EXISTS tables.country(
   relid       SERIAL  NOT NULL
  ,id          UUID    NOT NULL
  ,name        TEXT    NOT NULL
  ,code_2      CHAR(2) NOT NULL
  ,code_3      CHAR(3) NOT NULL
  ,has_regions BOOLEAN NOT NULL
);

SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_pk'
 )
\gexec

-- Create region table
CREATE TABLE IF NOT EXISTS tables.region(
   relid         SERIAL  NOT NULL
  ,country_relid INTEGER NOT NULL
  ,id            UUID    NOT NULL
  ,name          TEXT    NOT NULL
  ,code          TEXT    NOT NULL
);

SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_pk PRIMARY KEY(relid, country_relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_pk'
 )
\gexec

SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_country_fk FOREIGN KEY(country_relid) REFERENCES tables.country(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_pk'
 )
\gexec
