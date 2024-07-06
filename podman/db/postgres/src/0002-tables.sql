-- Create tables schema
CREATE SCHEMA IF NOT EXISTS tables AUTHORIZATION app_objects;

-- Create country table
CREATE TABLE IF NOT EXISTS tables.country(
	 relid INTEGER
	,name  TEXT NOT NULL
	,code_2 CHAR(2) NOT NULL
	,code_3 CHAR(3) NOT NULL
)

SELECT 'ALTER TABLE tables.COUNTRY ADD CONSTRAINT country_pk PRIMARY KEY(relid)'
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
	 relid INTEGER
	,name  TEXT NOT NULL
	,code  TEXT NOT NULL
)

SELECT 'ALTER TABLE tables.region ADD CONSTRAINT region_pk PRIMARY KEY(relid)'
 WHERE NOT EXISTS (
   SELECT NULL
     FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
    WHERE TABLE_SCHEMA    = 'tables'
      AND TABLE_NAME      = 'region'
      AND CONSTRAINT_NAME = 'region_pk'
 )
\gexec

CREATE TABLE IF NOT EXISTS tables.customer(
	 relid       INTEGER
	,id          UUID GENERATED ALWAYS AS RANDOM_UUID() STORED
	,version     INTEGER NOT NULL DEFAULT 1
	,created_at  TIMESTAMP WITHOUT TIME ZONE GENERATED ALWAYS AS CURRENT_TIMESTAMP STORED
	,modified_at TIMESTAMP WITHOUT TIME ZONE NOT NULL
	,first_name  TEXT NOT NULL
	,middle_name TEXT
	,last_name   TEXT NOT NULL
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

CREATE TABLE IF NOT EXISTS tables.address(
	 relid          INTEGER
	,customer_relid INTEGER
	,id             UUID GENERATED ALWAYS AS RANDOM_UUID() STORED
	,version        INTEGER NOT NULL DEFAULT 1
	,created_at     TIMESTAMP WITHOUT TIME ZONE GENERATED ALWAYS AS CURRENT_TIMESTAMP STORED
	,modified_at    TIMESTAMP WITHOUT TIME ZONE NOT NULL
	,country_relid  INTEGER NOT NULL
	,region_relid   INTEGER
	,city           TEXT NOT NULL
	,address        TEXT NOT NULL
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
