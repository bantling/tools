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
  ,ord                 INTEGER NOT NULL
);

-- Update base table modified dates for each update statement
CREATE OR REPLACE TRIGGER country_tg AFTER UPDATE ON tables.country
REFERENCING NEW TABLE AS NEW
FOR EACH STATEMENT EXECUTE FUNCTION code.UPDATE_BASE();

SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_pk'
 )
\gexec

SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_uk_name UNIQUE(name)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_uk_name'
 )
\gexec

SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_uk_code_2 UNIQUE(code_2)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_uk_code_2'
 )
\gexec

SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_uk_code_3 UNIQUE(code_3)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_uk_code_3'
 )
\gexec

SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_relid_fk FOREIGN KEY(relid) REFERENCES tables.base(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_fk'
 )
\gexec

SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_ck_mailing_fields CHECK((has_mailing_code = (mailing_code_match IS NOT NULL)) AND (has_mailing_code = (mailing_code_format IS NOT NULL)))'
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
  ,ord           INTEGER NOT NULL
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

SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_uk_name UNIQUE(name, country_relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_uk_name'
 )
\gexec

SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_uk_code UNIQUE(code, country_relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_uk_code'
 )
\gexec

SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_relid_fk FOREIGN KEY(relid) REFERENCES tables.base(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_fk'
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