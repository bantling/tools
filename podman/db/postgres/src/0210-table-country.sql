-- Create country table
CREATE TABLE IF NOT EXISTS tables.country(
   relid               BIGINT
  ,name                TEXT    NOT NULL
  ,code_2              CHAR(2) NOT NULL
  ,code_3              CHAR(3) NOT NULL
  ,has_regions         BOOLEAN NOT NULL
  ,has_mailing_code    BOOLEAN NOT NULL
  ,mailing_code_match  TEXT
  ,mailing_code_format TEXT
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

SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_ck_mailing_fields CHECK((has_mailing_code = mailing_code_match IS NOT NULL) AND (has_mailing_code = mailing_code_format IS NOT NULL))'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_ck_mailing_fields'
 )
\gexec

-- Create region table
CREATE TABLE IF NOT EXISTS tables.region(
   relid                 BIGINT
  ,country_relid INTEGER NOT NULL
  ,name          TEXT    NOT NULL
  ,code          TEXT    NOT NULL
);

SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_pk PRIMARY KEY(relid)'
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
      AND CONSTRAINT_NAME = 'region_country_fk'
 )
\gexec
