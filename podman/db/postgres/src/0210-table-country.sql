-- =======================
-- ==== country table ====
-- =======================
CREATE TABLE IF NOT EXISTS tables.country(
   name                TEXT    NOT NULL
  ,code_2              CHAR(2) NOT NULL
  ,code_3              CHAR(3) NOT NULL
  ,has_regions         BOOLEAN NOT NULL
  ,has_mailing_code    BOOLEAN NOT NULL
  ,mailing_code_match  TEXT
  ,mailing_code_format TEXT
  ,ord                 INTEGER NOT NULL
) INHERITS (tables.base);

-- Base trigger
CREATE OR REPLACE TRIGGER country_tg_modified_row
BEFORE INSERT OR UPDATE ON tables.country
FOR EACH ROW
EXECUTE FUNCTION base_tg_modified_row_fn();

-- Primary key
SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_pk'
 )
\gexec

-- Unique name
SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_uk_name UNIQUE(name)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_uk_name'
 )
\gexec

-- Unique code_2
SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_uk_code_2 UNIQUE(code_2)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_uk_code_2'
 )
\gexec

-- Unique code_3
SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_uk_code_3 UNIQUE(code_3)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_uk_code_3'
 )
\gexec

-- Check constraint
-- - If has_mailing_code is true , then mailing_code_match and mailing_code_format must both be NON-NULL
-- - If has_mailing_code is false, then mailing_code_match and mailing_code_format must both be NULL
SELECT 'ALTER TABLE tables.country ADD CONSTRAINT country_ck_mailing_fields CHECK((has_mailing_code = (mailing_code_match IS NOT NULL)) AND (has_mailing_code = (mailing_code_format IS NOT NULL)))'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'country'
      AND CONSTRAINT_NAME = 'country_ck_mailing_fields'
 )
\gexec

-- ==================
-- == region table ==
-- ==================
CREATE TABLE IF NOT EXISTS tables.region(
   country_relid INTEGER NOT NULL
  ,name          TEXT    NOT NULL
  ,code          TEXT    NOT NULL
  ,ord           INTEGER NOT NULL
) INHERITS(tables.base);

-- Base trigger
CREATE OR REPLACE TRIGGER region_tg_modified_row
BEFORE INSERT OR UPDATE ON tables.region
FOR EACH ROW
EXECUTE FUNCTION base_tg_modified_row_fn();

-- Primary key
SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_pk'
 )
\gexec

-- Unique (name, country)
SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_uk_name_country UNIQUE(name, country_relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_uk_name'
 )
\gexec

-- Unique (code, country)
SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_uk_code_country UNIQUE(code, country_relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_uk_code'
 )
\gexec

-- Country exists
SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_country_fk FOREIGN KEY(country_relid) REFERENCES tables.country(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_country_fk'
 )
\gexec
