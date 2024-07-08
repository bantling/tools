-- Customer
CREATE TABLE IF NOT EXISTS tables.customer(
	 relid       INTEGER                     NOT NULL
	,id          UUID                        NOT NULL
	,version     INTEGER                     NOT NULL
	,created_at  TIMESTAMP WITHOUT TIME ZONE NOT NULL
	,modified_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
	,first_name  TEXT                        NOT NULL
	,middle_name TEXT
	,last_name   TEXT                        NOT NULL
);

SELECT 'ALTER TABLE tables.customer ADD CONSTRAINT customer_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'customer'
      AND CONSTRAINT_NAME = 'custommer_pk'
 )
\gexec

-- Address
CREATE TABLE IF NOT EXISTS tables.address(
	 relid          INTEGER                     NOT NULL
	,customer_relid INTEGER                     NOT NULL
	,id             UUID                        NOT NULL
	,version        INTEGER                     NOT NULL
	,created_at     TIMESTAMP WITHOUT TIME ZONE NOT NULL
	,modified_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL
	,country_relid  INTEGER                     NOT NULL
	,region_relid   INTEGER
	,city           TEXT                        NOT NULL
	,address        TEXT                        NOT NULL
	,mailing_code   TEXT
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

SELECT 'ALTER TABLE tables.address ADD CONSTRAINT address_customer_fk FOREIGN KEY(customer_relid) REFERENCES tables.customer(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'address'
      AND CONSTRAINT_NAME = 'address_customer_fk'
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

SELECT 'ALTER TABLE tables.address ADD CONSTRAINT address_region_fk FOREIGN KEY(region_relid, country_relid) REFERENCES tables.region(relid, country_relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'address'
      AND CONSTRAINT_NAME = 'address_region_fk'
 )
\gexec
