\c mydb

-- Customer
INSERT INTO myapp.customer
         (id               , first_name, middle_name, last_name)
SELECT * FROM (
  VALUES (gen_random_uuid(), 'Jane'    , NULL       , 'Doe'    )
        ,(gen_random_uuid(), 'John'    , NULL       , 'Doe'    )
        ,(gen_random_uuid(), 'James'    , NULL       , 'Doe'    )
) t
 WHERE NOT EXISTS(SELECT 1 FROM myapp.customer);

-- Address
INSERT INTO myapp.address
         (id               , customer_rel_id, address         , city       , region, country, mail_code)
SELECT * FROM (
  VALUES (gen_random_uuid(), 1              , '123 Sesame St' , 'New York' , 'NY'  , 'USA'  , '12345'  )
        ,(gen_random_uuid(), 1              , '3860 Gorham St', 'London'   , 'ON'  , 'CAN'  , 'N0N 0N0')
        ,(gen_random_uuid(), 2              , '2422 Brand Rd' , 'Saskatoon', 'SK'  , 'CAN'  , 'S7K 1W8')
        ,(gen_random_uuid(), 3              , '521 102nd Ave' , 'Trail'    , 'BC'  , 'CAN'  , 'V1R 3W5')
) t
 WHERE NOT EXISTS(SELECT 1 FROM myapp.address);

-- Book
INSERT INTO myapp.book
         (id               , name                  , author                 , theyear, pages, isbn           )
SELECT * FROM (
  VALUES (gen_random_uuid(), 'Ruins of Isis'       , 'Marion Zimmer Bradley', 1978   , 265  , '9780671468439'),
         (gen_random_uuid(), 'I, Robot'            , 'Isaac Asimov'         , 1950   , 250  , '9780553900330'),
         (gen_random_uuid(), 'The End of Eternity' , 'Isaac Asimov'         , 1955   , 260  , '9780765319197'),
         (gen_random_uuid(), 'The Bicentennial Man', 'Isaac Asimov'         , 1976   , 270  , '9781857989328'),
         (gen_random_uuid(), 'The Naked Sun'       , 'Isaac Asimov'         , 1956   , 280  , '9780553293395')
) t
 WHERE NOT EXISTS(SELECT 1 FROM myapp.book);

-- Movie
INSERT INTO myapp.movie
         (id               , name                             , director        , theyear, duration          , imdb       )
SELECT * FROM (
  VALUES (gen_random_uuid(), 'Star Trek II: The Wrath of Kahn', 'Nicholas Meyer', 1982   , INTERVAL 'PT1H53M', 'tt0084726'),
         (gen_random_uuid(), 'I, Robot'                       , 'Alex Proyas'   , 2004   , INTERVAL 'PT1H55M', 'tt0343818'),
         (gen_random_uuid(), 'Bicentennial Man'               , 'Chris Columbus', 1999   , INTERVAL 'PT2H12M', 'tt0182789')
) t
 WHERE NOT EXISTS(SELECT 1 FROM myapp.movie);

-- Invoice
INSERT INTO myapp.invoice
         (id               , customer_rel_id, purchased_on          , invoice_number)
SELECT * FROM (
  VALUES (gen_random_uuid(), 1            , '2020-01-01 12:00:00'::TIMESTAMP, '1234'       ),
         (gen_random_uuid(), 2            , '2021-02-02 13:00:00'::TIMESTAMP, '5678'       )
) t
 WHERE NOT EXISTS(SELECT 1 FROM myapp.invoice);

-- Invoice Line
INSERT INTO myapp.invoice_line
         (id               , invoice_rel_id, product_oid                 , product_rel_id, line, quantity, price)
SELECT * FROM (
  VALUES (gen_random_uuid(), 1           , 'myapp.book'::regclass::oid , 1               , 1   , 3       , 10.00),
         (gen_random_uuid(), 1           , 'myapp.book'::regclass::oid , 2               , 2   , 4       , 15.00),
         (gen_random_uuid(), 2           , 'myapp.movie'::regclass::oid, 1               , 1   , 1       , 20.00),
         (gen_random_uuid(), 2           , 'myapp.movie'::regclass::oid, 2               , 2   , 1       , 25.00)
) t
 WHERE NOT EXISTS(SELECT 1 FROM myapp.invoice_line);

\q
