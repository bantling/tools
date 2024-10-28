-- Address types
CREATE TABLE IF NOT EXISTS tables.address_type(
   relid         BIGINT
  ,name  TEXT    NOT NULL
  ,ord   INTEGER NOT NULL -- ordering
);

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

-- Address
CREATE TABLE IF NOT EXISTS tables.address(
   relid         BIGINT
  ,type_relid    BIGINT
  ,country_relid BIGINT NOT NULL
  ,region_relid  BIGINT
  ,city          TEXT   NOT NULL
  ,address       TEXT   NOT NULL
  ,address_2     TEXT
  ,address_3     TEXT
  ,mailing_code  TEXT
);

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

-- Individual Customer
CREATE TABLE IF NOT EXISTS tables.customer_person(
   relid         BIGINT
  ,address_relid BIGINT
  ,first_name    TEXT   NOT NULL
  ,middle_name   TEXT
  ,last_name     TEXT   NOT NULL
);

SELECT 'ALTER TABLE tables.customer_person ADD CONSTRAINT customer_person_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer_person'
      AND CONSTRAINT_NAME = 'custommer_person_pk'
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

-- Business Customer
CREATE TABLE IF NOT EXISTS tables.customer_business(
   relid BIGINT
  ,name  TEXT   NOT NULL
);

SELECT 'ALTER TABLE tables.customer_business ADD CONSTRAINT customer_business_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer_business'
      AND CONSTRAINT_NAME = 'customer_business_pk'
 )
\gexec

-- Join a business with address(es)
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
