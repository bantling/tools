-- ========================
-- == address type table ==
-- ========================
CREATE TABLE IF NOT EXISTS tables.address_type(
   name  TEXT    NOT NULL
  ,ord   INTEGER NOT NULL
) INHERITS(tables.base);

-- Base trigger
CREATE OR REPLACE TRIGGER address_type_tg_modified_row
BEFORE INSERT OR UPDATE ON tables.address_type
FOR EACH ROW
EXECUTE FUNCTION base_tg_modified_row_fn();

SELECT 'ALTER TABLE tables.address_type ADD CONSTRAINT address_type_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'address_type'
      AND CONSTRAINT_NAME = 'address_type_pk'
 )
\gexec

SELECT 'ALTER TABLE tables.address_type ADD CONSTRAINT address_type_uk_name UNIQUE(name)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'address_type'
      AND CONSTRAINT_NAME = 'address_type_uk_name'
 )
\gexec

-- ===================
-- == address table ==
-- ===================
CREATE TABLE IF NOT EXISTS tables.address(
   type_relid    BIGINT
  ,country_relid BIGINT NOT NULL
  ,region_relid  BIGINT
  ,city          TEXT   NOT NULL
  ,address       TEXT   NOT NULL
  ,address_2     TEXT
  ,address_3     TEXT
  ,mailing_code  TEXT
) INHERITS(tables.base);

-- Base trigger
CREATE OR REPLACE TRIGGER address_tg_modified_row
BEFORE INSERT OR UPDATE ON tables.address
FOR EACH ROW
EXECUTE FUNCTION base_tg_modified_row_fn();

SELECT 'ALTER TABLE tables.address ADD CONSTRAINT address_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'address'
      AND CONSTRAINT_NAME = 'address_pk'
 )
\gexec

SELECT 'ALTER TABLE tables.address ADD CONSTRAINT address_type_fk FOREIGN KEY(type_relid) REFERENCES tables.address_type(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'address'
      AND CONSTRAINT_NAME = 'address_type_fk'
 )
\gexec

SELECT 'ALTER TABLE tables.address ADD CONSTRAINT address_country_fk FOREIGN KEY(country_relid) REFERENCES tables.country(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'address'
      AND CONSTRAINT_NAME = 'address_country_fk'
 )
\gexec

SELECT 'ALTER TABLE tables.address ADD CONSTRAINT address_region_fk FOREIGN KEY(region_relid) REFERENCES tables.region(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'address'
      AND CONSTRAINT_NAME = 'address_region_fk'
 )
\gexec

-- =====================
-- customer person table
-- =====================
CREATE TABLE IF NOT EXISTS tables.customer_person(
   address_relid BIGINT
  ,first_name    TEXT   NOT NULL
  ,middle_name   TEXT
  ,last_name     TEXT   NOT NULL
) INHERITS(tables.base);

-- Base trigger
CREATE OR REPLACE TRIGGER customer_person_tg_modified_row
BEFORE INSERT OR UPDATE ON tables.customer_person
FOR EACH ROW
EXECUTE FUNCTION base_tg_modified_row_fn();

SELECT 'ALTER TABLE tables.customer_person ADD CONSTRAINT customer_person_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer_person'
      AND CONSTRAINT_NAME = 'customer_person_pk'
 )
\gexec

SELECT 'ALTER TABLE tables.customer_person ADD CONSTRAINT customer_person_addresss_fk FOREIGN KEY(address_relid) REFERENCES tables.address(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer_person'
      AND CONSTRAINT_NAME = 'customer_person_address_fk'
 )
\gexec

-- ==========================
-- == business customer table
-- ==========================
CREATE TABLE IF NOT EXISTS tables.customer_business(
   name  TEXT   NOT NULL
) INHERITS(tables.base);

-- Base trigger
CREATE OR REPLACE TRIGGER customer_business_tg_modified_row
BEFORE INSERT OR UPDATE ON tables.customer_business
FOR EACH ROW
EXECUTE FUNCTION base_tg_modified_row_fn();

SELECT 'ALTER TABLE tables.customer_business ADD CONSTRAINT customer_business_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer_business'
      AND CONSTRAINT_NAME = 'customer_business_pk'
 )
\gexec

-- =================================
-- == business address join table ==
-- =================================
CREATE TABLE IF NOT EXISTS tables.customer_business_address_jt(
   business_relid BIGINT
  ,address_relid  BIGINT
);

SELECT 'ALTER TABLE tables.customer_business_address_jt ADD CONSTRAINT customer_business_address_jt_pk PRIMARY KEY(business_relid, address_relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer_business_address'
      AND CONSTRAINT_NAME = 'customer_business_address_jt_pk'
 )
\gexec

SELECT 'ALTER TABLE tables.customer_business_address_jt ADD CONSTRAINT customer_business_address_jt_bfk FOREIGN KEY(business_relid) REFERENCES tables.customer_business(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer_business_address'
      AND CONSTRAINT_NAME = 'customer_business_address_jt_bfk'
 )
\gexec

SELECT 'ALTER TABLE tables.customer_business_address_jt ADD CONSTRAINT customer_business_address_jt_afk FOREIGN KEY(address_relid) REFERENCES tables.address(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer_business_address'
      AND CONSTRAINT_NAME = 'customer_business_address_jt_afk'
 )
\gexec

-- Trigger function to ensure that address related to a customer_business_address have an address type
CREATE OR REPLACE FUNCTION customer_business_address_jt_tg_address_type_fn() RETURNS trigger AS
$$
BEGIN
  IF (SELECT type_relid IS NULL FROM tables.address WHERE relid = NEW.address_relid) THEN
    -- The related address has no address type
    RAISE EXCEPTION 'A customer business address must have an address type';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

-- Base trigger
CREATE OR REPLACE TRIGGER customer_business_address_jt_tg_modified_row
BEFORE INSERT OR UPDATE ON tables.customer_business_address_jt
FOR EACH ROW
EXECUTE FUNCTION customer_business_address_jt_tg_address_type_fn();
