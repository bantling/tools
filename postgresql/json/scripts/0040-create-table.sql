\c mydb

--
-- Shared full text search
--
-- tbl_oid      object id for the source table
-- rel_id       PK of the source table row
-- descriptor   full text description of the source table row
-- search_terms terms to search by
--
-- PK: tbl_oid, rel_id
--

-- Table
CREATE TABLE IF NOT EXISTS myapp.shared_search(
  tbl_oid      OID      NOT NULL,
  rel_id       INTEGER  NOT NULL,
  description  VARCHAR  NOT NULL,
  search_terms TSVECTOR NOT NULL
);

-- PK
SELECT 'ALTER TABLE myapp.shared_search ADD CONSTRAINT shared_search_pk PRIMARY KEY (tbl_oid, rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'shared_search'
      AND constraint_name = 'shared_search_pk'
 )
\gexec

-- Index on descriptor field for full text searches
CREATE INDEX IF NOT EXISTS shared_search_ix_search_terms ON myapp.shared_search USING GIN(search_terms);

-- Statement level trigger for insert and update events to copy descriptor to shared_search table.
-- Any table this trigger is applied to:
--  Has to contain its own rel_id and descriptor columns.
--  Has to specify that the name of the table of data being inserted/updated is NEW_TABLE.
CREATE OR REPLACE FUNCTION myapp_update_shared_search() RETURNS TRIGGER AS
$$
BEGIN
  INSERT INTO myapp.shared_search(tbl_oid, rel_id, descriptor)
  -- TG_RELID is pre-defined var containing object id of table the trigger is applied to
  SELECT TG_RELID, rel_id, description, search_terms
    FROM NEW_TABLE
      ON CONFLICT (tbl_oid, rel_id)
      -- EXCLUDED is pre-defined var for row to be inserted
      DO UPDATE SET description  = EXCLUDED.description
                   ,search_terms = EXCLUDED.search_terms;
  RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- Statement level trigger for delete events to delete from shared_search table.
-- Any table this trigger is applied to has to specify that the name of the table of data being deleted is OLD_TABLE.
CREATE OR REPLACE FUNCTION myapp_delete_shared_search() RETURNS TRIGGER AS
$$
BEGIN
  DELETE FROM myapp.shared_search msr
  -- TG_RELID is pre-defined var containing object id of table the trigger is applied to
   WHERE msr.tbl_oid = TG_RELID
     AND msr.rel_id IN (SELECT rel_id FROM OLD_TABLE);
  RETURN NULL;
END
$$ LANGUAGE plpgsql;

--
-- Customer
--
-- rel_id      PK
-- descriptor  full text description
-- id          UUID
-- first_name  first name
-- middle_name middle name
-- last_name   last name
--
-- PK: rel_id
-- UK: id
--

-- Table
CREATE TABLE IF NOT EXISTS myapp.customer(
  rel_id      INTEGER GENERATED ALWAYS AS IDENTITY,
  id          UUID    NOT NULL,
  first_name  VARCHAR NOT NULL,
  middle_name VARCHAR,
  last_name   VARCHAR NOT NULL
);

-- PK
SELECT 'ALTER TABLE myapp.customer ADD CONSTRAINT customer_pk PRIMARY KEY (rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'customer'
      AND constraint_name = 'customer_pk'
 )
\gexec

-- UK
SELECT 'ALTER TABLE myapp.customer ADD CONSTRAINT customer_uk_id UNIQUE (id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'customer'
      AND constraint_name = 'customer_uk_id'
 )
\gexec

-- Statement level trigger for insert and update events to generate search terms to insert into shared_search table
CREATE OR REPLACE FUNCTION myapp_update_customer() RETURNS TRIGGER AS
$$
BEGIN
    INSERT
      INTO myapp.shared_search(
             tbl_oid
            ,rel_id
            ,description
            ,search_terms
           )
    SELECT
           TG_RELID
          ,NEW_TABLE.rel_id
          ,CONCAT(NEW_TABLE.first_name, COALESCE(CONCAT(' ', NEW_TABLE.middle_name), ''), ' ', NEW_TABLE.last_name)
          ,TO_TSVECTOR(CONCAT(NEW_TABLE.first_name, ' ', NEW_TABLE.last_name))
      FROM NEW_TABLE
        ON CONFLICT ON CONSTRAINT shared_search_pk DO
    UPDATE SET
           description  = (SELECT CONCAT(NEW_TABLE.first_name, COALESCE(CONCAT(' ', NEW_TABLE.middle_name), ''), ' ', NEW_TABLE.last_name)
                             FROM NEW_TABLE
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id)
          ,search_terms = (SELECT TO_TSVECTOR(CONCAT(NEW_TABLE.first_name, ' ', NEW_TABLE.last_name))
                             FROM NEW_TABLE
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id);

  RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- Statement level trigger to insert descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_customer_search_insert_tg
  AFTER INSERT ON myapp.customer
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_customer();

-- Statement level trigger to update descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_customer_search_update_tg
  AFTER UPDATE ON myapp.customer
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_customer();

-- Statement level trigger to delete descriptor from shared_search table
CREATE OR REPLACE TRIGGER myapp_customer_search_delete_tg
  AFTER DELETE ON myapp.customer
  REFERENCING OLD TABLE AS OLD_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_delete_shared_search();

--
-- Address
--
-- rel_id      PK
-- descriptor  full text description
-- id          UUID
-- address street address
-- city    city
-- region  state/province
-- country country
--
-- PK: rel_id
-- UK: id
--

-- Table
CREATE TABLE IF NOT EXISTS myapp.address(
  rel_id          INTEGER GENERATED ALWAYS AS IDENTITY,
  id              UUID    NOT NULL,
  customer_rel_id INTEGER NOT NULL,
  address         VARCHAR NOT NULL,
  city            VARCHAR NOT NULL,
  region          VARCHAR NULL,
  country         VARCHAR NOT NULL,
  mail_code       VARCHAR NULL
);

-- PK
SELECT 'ALTER TABLE myapp.address ADD CONSTRAINT address_pk PRIMARY KEY (rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'address'
      AND constraint_name = 'address_pk'
 )
\gexec

-- UK
SELECT 'ALTER TABLE myapp.address ADD CONSTRAINT address_uk_id UNIQUE (id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'address'
      AND constraint_name = 'address_uk_id'
 )
\gexec

-- FK
SELECT 'ALTER TABLE myapp.address ADD CONSTRAINT address_fk_customer_rel_id FOREIGN KEY(customer_rel_id) REFERENCES myapp.customer(rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'address'
      AND constraint_name = 'address_fk_customer_rel_id'
 )
\gexec

-- Statement level trigger for insert and update events to generate search terms to insert into shared_search table
CREATE OR REPLACE FUNCTION myapp_update_address() RETURNS TRIGGER AS
$$
BEGIN
    INSERT
      INTO myapp.shared_search(
             tbl_oid
            ,rel_id
            ,description
            ,search_terms
           )
    SELECT
           TG_RELID
          ,NEW_TABLE.rel_id
          ,CONCAT(NEW_TABLE.address, ', ', NEW_TABLE.city, ', ',  NEW_TABLE.region, ', ', NEW_TABLE.country, ', ', NEW_TABLE.mail_code)
          ,TO_TSVECTOR(CONCAT(NEW_TABLE.address, ' ', NEW_TABLE.city,  ' ', NEW_TABLE.region, ' ', NEW_TABLE.country, ' ', NEW_TABLE.mail_code))
      FROM NEW_TABLE
        ON CONFLICT ON CONSTRAINT shared_search_pk DO
    UPDATE SET
           description  = (SELECT CONCAT(NEW_TABLE.address, ', ', NEW_TABLE.city, ', ',  NEW_TABLE.region, ', ', NEW_TABLE.country, ', ', NEW_TABLE.mail_code)
                             FROM NEW_TABLE
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id)
          ,search_terms = (SELECT TO_TSVECTOR(CONCAT(NEW_TABLE.address, ' ', NEW_TABLE.city, ' ',  NEW_TABLE.region, ' ', NEW_TABLE.country, ' ', NEW_TABLE.mail_code))
                             FROM NEW_TABLE
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id);

  RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- Statement level trigger to insert descriptor in shared_search table
CREATE OR REPLACE TRIGGER address_search_insert_tg
  AFTER INSERT ON myapp.address
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_address();

-- Statement level trigger to update descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_address_search_update_tg
  AFTER UPDATE ON myapp.address
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_address();

-- Statement level trigger to delete descriptor from shared_search table
CREATE OR REPLACE TRIGGER address_search_delete_tg
  AFTER DELETE ON myapp.address
  REFERENCING OLD TABLE AS OLD_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_delete_shared_search();

--
-- Book
--
-- rel_id     PK
-- descriptor full text description
-- id         UUID
-- name       name of the book
-- author     author of the book
-- theyear    year of the book
-- pages      number of pages in the book
-- isbn       ISBN number of the book
--
-- PK: rel_id
-- UK: id
--

-- Table
CREATE TABLE IF NOT EXISTS myapp.book(
  rel_id  INTEGER GENERATED ALWAYS AS IDENTITY,
  id      UUID    NOT NULL,
  name    VARCHAR NOT NULL,
  author  VARCHAR NOT NULL,
  theyear INTEGER NOT NULL,
  pages   INTEGER NOT NULL,
  isbn    VARCHAR NOT NULL
);

-- PK
SELECT 'ALTER TABLE myapp.book ADD CONSTRAINT book_pk PRIMARY KEY (rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'book'
      AND constraint_name = 'book_pk'
 )
\gexec

-- UK
SELECT 'ALTER TABLE myapp.book ADD CONSTRAINT book_uk_id UNIQUE (id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'book'
      AND constraint_name = 'book_uk_id'
 )
\gexec

-- Statement level trigger for insert and update events to generate search terms to insert into shared_search table
CREATE OR REPLACE FUNCTION myapp_update_book() RETURNS TRIGGER AS
$$
BEGIN
    INSERT
      INTO myapp.shared_search(
             tbl_oid
            ,rel_id
            ,description
            ,search_terms
           )
    SELECT
           TG_RELID
          ,NEW_TABLE.rel_id
          ,CONCAT(NEW_TABLE.name, ' by ', NEW_TABLE.author, ' in ', NEW_TABLE.theyear, ' pp ', NEW_TABLE.pages, ' isbn ', NEW_TABLE.isbn)
          ,TO_TSVECTOR(CONCAT(NEW_TABLE.name, ' ', NEW_TABLE.author, ' ', NEW_TABLE.theyear, ' ', NEW_TABLE. isbn))
      FROM NEW_TABLE
        ON CONFLICT ON CONSTRAINT shared_search_pk DO
    UPDATE SET
           description  = (SELECT CONCAT(NEW_TABLE.name, ' by ', NEW_TABLE.author, ' in ', NEW_TABLE.theyear, ' pp ', NEW_TABLE.pages, ' isbn ', NEW_TABLE.isbn)
                             FROM NEW_TABLE
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id)
          ,search_terms = (SELECT TO_TSVECTOR(CONCAT(NEW_TABLE.name, ' ', NEW_TABLE.author, ' ', NEW_TABLE.theyear, ' ', NEW_TABLE.isbn))
                             FROM NEW_TABLE
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id);

  RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- Statement level trigger to insert descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_book_search_insert_tg
  AFTER INSERT ON myapp.book
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_book();

-- Statement level trigger to update descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_book_search_update_tg
  AFTER UPDATE ON myapp.book
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_book();

-- Statement level trigger to delete descriptor from shared_search table
CREATE OR REPLACE TRIGGER myapp_book_search_delete_tg
  AFTER DELETE ON myapp.book
  REFERENCING OLD TABLE AS OLD_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_delete_shared_search();

--
-- Movie
--
-- rel_id     PK
-- descriptor full text description
-- id         UUID
-- name       name of the movie
-- director   director of the movie
-- theyear    year of the movie
-- duration   length of the movie
-- imdb       IMDB number of the movie
--
-- PK: rel_id
-- UK: id
--

-- Table
CREATE TABLE IF NOT EXISTS myapp.movie(
  rel_id   INTEGER  GENERATED ALWAYS AS IDENTITY,
  id       UUID     NOT NULL,
  name     VARCHAR  NOT NULL,
  director VARCHAR  NOT NULL,
  theyear  INTEGER  NOT NULL,
  duration INTERVAL NOT NULL,
  imdb     VARCHAR  NOT NULL
);

-- PK
SELECT 'ALTER TABLE myapp.movie ADD CONSTRAINT movie_pk PRIMARY KEY (rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'movie'
      AND constraint_name = 'movie_pk'
 )
\gexec

-- UK
SELECT 'ALTER TABLE myapp.movie ADD CONSTRAINT movie_uk_id UNIQUE (id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'movie'
      AND constraint_name = 'movie_uk_id'
 )
\gexec

-- Statement level trigger for insert and update events to generate search terms to insert into shared_search table
CREATE OR REPLACE FUNCTION myapp_update_movie() RETURNS TRIGGER AS
$$
BEGIN
    INSERT
      INTO myapp.shared_search(
             tbl_oid
            ,rel_id
            ,description
            ,search_terms
           )
    SELECT
           TG_RELID
          ,NEW_TABLE.rel_id
          ,CONCAT(NEW_TABLE.name, ' directed by ', NEW_TABLE.director, ' in ', NEW_TABLE.theyear, ' ', NEW_TABLE.duration, ' imdb ', NEW_TABLE.imdb)
          ,TO_TSVECTOR(CONCAT(NEW_TABLE.name, ' ', NEW_TABLE.director, ' ', NEW_TABLE.theyear, ' ', NEW_TABLE.imdb))
      FROM NEW_TABLE
        ON CONFLICT ON CONSTRAINT shared_search_pk DO
    UPDATE SET
           description  = (SELECT CONCAT(NEW_TABLE.name, ' directed by ', NEW_TABLE.director, ' in ', NEW_TABLE.theyear, ' ', duration, ' imdb ', NEW_TABLE.imdb)
                             FROM NEW_TABLE
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id)
          ,search_terms = (SELECT TO_TSVECTOR(CONCAT(NEW_TABLE.name, ' ', NEW_TABLE.director, ' ', NEW_TABLE.theyear, ' ', NEW_TABLE.imdb))
                             FROM NEW_TABLE
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id);

  RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- Statement level trigger to insert descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_movie_search_insert_tg
  AFTER INSERT ON myapp.movie
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_movie();

-- Statement level trigger to update descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_movie_search_update_tg
  AFTER UPDATE ON myapp.movie
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_movie();

-- Statement level trigger to delete descriptor from shared_search table
CREATE OR REPLACE TRIGGER myapp_movie_search_delete_tg
  AFTER DELETE ON myapp.movie
  REFERENCING OLD TABLE AS OLD_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_delete_shared_search();

--
-- Invoice
--
-- rel_id          PK
-- descriptor      full text description
-- id              UUID
-- customer_rel_id primary key of the customer who paid for the invoice
-- purchased_on    date of ther invoice
-- invoice_number  number of the invoice
--
-- PK: rel_id
-- UK: id
-- FK: customer_rel_id
--

CREATE TABLE IF NOT EXISTS myapp.invoice(
  rel_id          INTEGER                     GENERATED ALWAYS AS IDENTITY,
  id              UUID                        NOT NULL,
  customer_rel_id INTEGER                     NOT NULL,
  purchased_on    TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  invoice_number  VARCHAR                     NOT NULL
);

-- PK
SELECT 'ALTER TABLE myapp.invoice ADD CONSTRAINT invoice_pk PRIMARY KEY (rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'invoice'
      AND constraint_name = 'invoice_pk'
 )
\gexec

-- UK
SELECT 'ALTER TABLE myapp.invoice ADD CONSTRAINT invoice_uk_id UNIQUE (id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'invoice'
      AND constraint_name = 'invoice_uk_id'
 )
\gexec

-- FK
SELECT 'ALTER TABLE myapp.invoice ADD CONSTRAINT invoice_fk_customer_rel_id FOREIGN KEY(customer_rel_id) REFERENCES myapp.customer(rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'invoice'
      AND constraint_name = 'invoice_fk_customer_rel_id'
 )
\gexec

-- Statement level trigger for insert and update events to generate search terms to insert into shared_search table
CREATE OR REPLACE FUNCTION myapp_update_invoice() RETURNS TRIGGER AS
$$
BEGIN
    INSERT
      INTO myapp.shared_search(
             tbl_oid
            ,rel_id
            ,description
            ,search_terms
           )
    SELECT
           TG_RELID
          ,NEW_TABLE.rel_id
          ,CONCAT(NEW_TABLE.invoice_number, ' purchased on ', NEW_TABLE.purchased_on, ' by ', CONCAT(c.first_name, ' ', c.last_name))
          ,TO_TSVECTOR(CONCAT(NEW_TABLE.invoice_number, ' ', c.first_name, ' ', c.last_name))
      FROM NEW_TABLE
      JOIN myapp.customer c
        ON c.rel_id = NEW_TABLE.customer_rel_id
        ON CONFLICT ON CONSTRAINT shared_search_pk DO
    UPDATE SET
           description  = (SELECT CONCAT(NEW_TABLE.invoice_number, ' purchased on ', NEW_TABLE.purchased_on, ' by ', CONCAT(c.first_name, ' ', c.last_name))
                             FROM NEW_TABLE
                             JOIN myapp.customer c
                               ON c.rel_id = NEW_TABLE.customer_rel_id
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id)
          ,search_terms = (SELECT TO_TSVECTOR(CONCAT(NEW_TABLE.invoice_number, ' ', c.first_name, ' ', c.last_name))
                             FROM NEW_TABLE
                             JOIN myapp.customer c
                               ON c.rel_id = NEW_TABLE.customer_rel_id
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id);

  RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- Statement level trigger to insert descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_invoice_search_insert_tg
  AFTER INSERT ON myapp.invoice
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_invoice();

-- Statement level trigger to update descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_invoice_search_update_tg
  AFTER UPDATE ON myapp.invoice
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_invoice();

-- Statement level trigger to delete descriptor from shared_search table
CREATE OR REPLACE TRIGGER myapp_invoice_search_delete_tg
  AFTER DELETE ON myapp.invoice
  REFERENCING OLD TABLE AS OLD_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_delete_shared_search();

--
-- Invoice Line
--
-- rel_id         PK
-- descriptor     full text description
-- id             UUID
-- product_oid    object id of the product table
-- product_rel_id PK of the product
-- invoice_rel_id primary key of the invoice containing the line
-- quantity       quantity of items of this type being purchased
-- price          cost of a single item of this type
-- extended       rounded quantity * price value
--
-- PK: rel_id
-- UK: id
-- FK: invoice_rel_id
--

CREATE TABLE IF NOT EXISTS myapp.invoice_line(
  rel_id         INTEGER      GENERATED ALWAYS AS IDENTITY,
  id             UUID         NOT NULL,
  invoice_rel_id INTEGER      NOT NULL,
  product_oid    OID          NOT NULL,
  product_rel_id INTEGER      NOT NULL,
  line           INTEGER      NOT NULL,
  quantity       INTEGER      NOT NULL,
  price          DECIMAL(8,2) NOT NULL,
  extended       DECIMAL(8,2) GENERATED ALWAYS AS (quantity * price) STORED
);

-- PK
SELECT 'ALTER TABLE myapp.invoice_line ADD CONSTRAINT invoice_line_pk PRIMARY KEY (rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'invoice_line'
      AND constraint_name = 'invoice_line_pk'
 )
\gexec

-- UK
SELECT 'ALTER TABLE myapp.invoice_line ADD CONSTRAINT invoice_line_uk_id UNIQUE (id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'invoice_line'
      AND constraint_name = 'invoice_line_uk_id'
 )
\gexec

-- FK
SELECT 'ALTER TABLE myapp.invoice_line ADD CONSTRAINT invoice_line_fk_invoice_rel_id FOREIGN KEY(invoice_rel_id) REFERENCES myapp.invoice(rel_id)'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'invoice_line'
      AND constraint_name = 'invoice_line_fk_invoice_rel_id'
 )
\gexec

-- CK
SELECT 'ALTER TABLE myapp.invoice_line ADD CONSTRAINT invoice_line_ck_product_oid CHECK (product_oid IN (''myapp.book''::regclass::oid, ''myapp.movie''::regclass::oid))'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.table_constraints
    WHERE table_schema    = 'myapp'
      AND table_name      = 'invoice_line'
      AND constraint_name = 'invoice_line_ck_product_oid'
 )
\gexec

-- Statement level trigger for insert and update events to generate search terms to insert into shared_search table
CREATE OR REPLACE FUNCTION myapp_update_invoice_line() RETURNS TRIGGER AS
$$
BEGIN
    INSERT
      INTO myapp.shared_search(
             tbl_oid
            ,rel_id
            ,description
            ,search_terms
           )
    SELECT
           TG_RELID
          ,NEW_TABLE.rel_id
          ,CONCAT(i.invoice_number, ' line ', NEW_TABLE.line, ' of ', NEW_TABLE.quantity, ' ', ss.description) description
          ,TO_TSVECTOR(CONCAT(i.invoice_number, ' ', NEW_TABLE.line, ' ', NEW_TABLE.quantity)) search_terms
      FROM NEW_TABLE
      JOIN myapp.invoice i
        ON i.rel_id = NEW_TABLE.invoice_rel_id
      JOIN myapp.shared_search ss
        ON ss.tbl_oid = NEW_TABLE.product_oid
       AND ss.rel_id = NEW_TABLE.product_rel_id
        ON CONFLICT ON CONSTRAINT shared_search_pk DO
    UPDATE SET
           description  = (SELECT CONCAT(i.invoice_number, ' line ', NEW_TABLE.line, ' of ', NEW_TABLE.quantity, ' ', ss.description)
                             FROM NEW_TABLE
                             JOIN myapp.invoice i
                               ON i.rel_id = NEW_TABLE.invoice_rel_id
                             JOIN myapp.shared_search ss
                               ON ss.tbl_oid = NEW_TABLE.product_oid
                              AND ss.rel_id = NEW_TABLE.product_rel_id
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id)
          ,search_terms = (SELECT TO_TSVECTOR(CONCAT(i.invoice_number, ' ', NEW_TABLE.line, ' ', NEW_TABLE.quantity))
                             FROM NEW_TABLE
                             JOIN myapp.invoice i
                               ON i.rel_id = NEW_TABLE.invoice_rel_id
                             JOIN myapp.shared_search ss
                               ON ss.tbl_oid = NEW_TABLE.product_oid
                              AND ss.rel_id = NEW_TABLE.product_rel_id
                            WHERE NEW_TABLE.rel_id = EXCLUDED.rel_id);

  RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- Statement level trigger to insert descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_invoice_line_search_insert_tg
  AFTER INSERT ON myapp.invoice_line
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_invoice_line();

-- Statement level trigger to update descriptor in shared_search table
CREATE OR REPLACE TRIGGER myapp_invoice_line_search_update_tg
  AFTER UPDATE ON myapp.invoice_line
  REFERENCING NEW TABLE AS NEW_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_update_invoice_line();

-- Statement level trigger to delete descriptor from shared_search table
CREATE OR REPLACE TRIGGER myapp_invoice_line_search_delete_tg
  AFTER DELETE ON myapp.invoice_line
  REFERENCING OLD TABLE AS OLD_TABLE
  FOR EACH STATEMENT EXECUTE FUNCTION myapp_delete_shared_search();

\q
