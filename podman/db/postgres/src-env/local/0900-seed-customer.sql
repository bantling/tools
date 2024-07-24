-- Seed addresses
WITH PARAMS AS (
  SELECT 5 num_rows
        ,(SELECT COUNT(*) FROM tables.address_type) num_address_types
        ,(SELECT COUNT(*) FROM tables.country     ) num_countries
)
-- SELECT * FROM PARAMS;
--  num_rows | num_address_types | num_countries 
-- ----------+-------------------+---------------
--         5 |                 3 |             3
-- (1 row)

, ADD_ROWS AS (
  SELECT p.*
    FROM PARAMS p
        ,generate_series(1, num_rows) r
)
-- SELECT * FROM ADD_ROWS;
--  num_rows | num_address_types | num_countries 
-- ----------+-------------------+---------------
--         5 |                 3 |             4
--         5 |                 3 |             4
--         5 |                 3 |             4
--         5 |                 3 |             4
--         5 |                 3 |             4
-- (5 rows)

, GEN_ADDRESS_COUNTRY_RELID AS (
  SELECT NULLIF((random() * d.num_address_types)::int, 0)      type_relid    -- null = person, number = business
        ,      (random() * (d.num_countries     - 1) + 1)::int country_relid
    FROM ADD_ROWS d
)
-- SELECT * FROM GEN_ADDRESS_COUNTRY_RELID;
--  type_relid | country_relid 
-- ------------+---------------
--           1 |             2
--           1 |             2
--             |             1
--           2 |             3
--           1 |             1
-- (5 rows)

-- region relid is a bit tricky:
-- country 1 region relids start at 1
-- country 2 region relids start at (max relid for country 1) + 1
-- country 3 region relids start at (max relid for country 2) + 1
-- provide minimum region relid for each country
, ADD_NUM_REGIONS_MIN_RELID AS (
  SELECT d.*
        ,NULLIF((SELECT COUNT(*) FROM tables.region r WHERE r.country_relid = d.country_relid), 0) num_regions
        ,(SELECT MIN(relid) FROM tables.region r WHERE r.country_relid = d.country_relid)          min_region_relid
    FROM GEN_ADDRESS_COUNTRY_RELID d
)
-- SELECT * FROM ADD_NUM_REGIONS_MIN_RELID;
--  type_relid | country_relid | num_regions | min_region_relid 
-- ------------+---------------+-------------+------------------
--           1 |             3 |             |                 
--           3 |             4 |          55 |               14
--             |             1 |             |                 
--           1 |             2 |          13 |                1
--           3 |             2 |          13 |                1
-- (5 rows)

-- pick a random number from 0 to num regions - 1
-- add minimum region relid for the country
, ADD_REGION_RELID AS (
  SELECT d.*
        ,((random() * (d.num_regions - 1)) + d.min_region_relid)::int region_relid
    FROM ADD_NUM_REGIONS_MIN_RELID d
)
-- SELECT * FROM ADD_REGION_RELID;
--  type_relid | country_relid | num_regions | min_region_relid | region_relid 
-- ------------+---------------+-------------+------------------+--------------
--           1 |             3 |             |                  |             
--           1 |             4 |          55 |               14 |           22
--           2 |             2 |          13 |                1 |            4
--           1 |             1 |             |                  |             
--           2 |             3 |             |                  |             
-- (5 rows)

, ADD_CITY AS (
  SELECT d.*
        ,CASE c.code_2
         WHEN 'AW' THEN -- Aruba
           jsonb_build_array(
              'Alto Vista'
             ,'Barcadera'
             ,'Bubali'
             ,'Companashi'
             ,'Cumana'
             ,'Cunucu Abao'
             ,'Malmok'
             ,'Moko'
             ,'Noord'
             ,'Oranjestad'
           ) -> (random() * 9)::int
         WHEN 'CA' THEN -- Canada
           jsonb_build_array(
              'Calgary'      , 'Edmonton'     -- AB
             ,'Victoria'     , 'Vancouver'    -- BC
             ,'Winnepeg'     , 'Brandon'      -- MB
             ,'Fredericton'  , 'Moncton'      -- NB
             ,'St John''s'   , 'Paradise'     -- NL
             ,'Yellowknife'  , 'Hay River'    -- NT
             ,'Halifax'      , 'Sydney'       -- NS
             ,'Iqaluit'      , 'Rankin Inlet' -- NU
             ,'Ottawa'       , 'Toronto'      -- ON
             ,'Charlottetown', 'Summerside'   -- PE
             ,'Quebec City'  , 'Montreal'     -- QC
             ,'Saskatoon'    , 'Regina'       -- SK
             ,'Whitehorse'   , 'Dawson City'  -- YT
           ) -> (random() * 25)::int
         WHEN 'CX' THEN -- Christmas Island
           jsonb_build_array(
              'Drimsite'
             ,'Flying Fish Cove'
             ,'Poon Saan'
             ,'Silver City'
           ) -> (random() * 3)::int
         WHEN 'US' THEN -- United States
           -- Postgres has limit of 100 function args, but we have 110 cities
           -- Use two sub arrays of 60 and 50 args and concatenate them using ||
           jsonb_build_array(
              'Montgomery'      , 'Birmingham'       -- AL
             ,'Juneau'          , 'Fairbanks'        -- AK
             ,'Aunu''u'         , 'Ofu'              -- AS
             ,'Phoenix'         , 'Tucson'           -- AZ
             ,'Little Rock'     , 'Fayetteville'     -- AR
             ,'Sacramento'      , 'San Diego'        -- CA
             ,'Denver'          , 'Castle Rock'      -- CO
             ,'Hartford'        , 'Bridgeport'       -- CT
             ,'Dover'           , 'Wilmington'       -- DE
             ,'Washington'      , 'Shaw'             -- DC
             ,'Tallahassee'     , 'Jacksonville'     -- FL
             ,'Atlanta'         , 'Columbus'         -- GA
             ,'Hagåtña'         , 'Dededo'           -- GU
             ,'Honolulu'        , 'Hilo'             -- HI
             ,'Boise'           , 'Meridian'         -- ID
             ,'Springfield'     , 'Chicago'          -- IL
             ,'Indianapolis'    , 'Fort Wayne'       -- IN
             ,'Des Moines'      , 'Cedar Rapids'     -- IA
             ,'Topeka'          , 'Wichita'          -- KS
             ,'Frankfort'       , 'Louisville'       -- KY
             ,'Baton Rouge'     , 'New Orleans'      -- LA
             ,'Augusta'         , 'Portland'         -- ME
             ,'Annapolis'       , 'Baltimore'        -- MD
             ,'Boston'          , 'Worcester'        -- MA
             ,'Lansing'         , 'Detroit'          -- MI
             ,'Saint Paul'      , 'Minneapolis'      -- MN
             ,'Jackson'         , 'Gulfport'         -- MS
             ,'Jefferson'       , 'Kansas'           -- MO
             ,'Helena'          , 'Billings'         -- MT
             ,'Lincoln'         , 'Omaha'            -- NE
           ) ||
           jsonb_build_array(
              'Carson City'     , 'Las Vegas'        -- NV
             ,'Concord'         , 'Manchester'       -- NH
             ,'Trenton'         , 'Newark'           -- NJ
             ,'Santa Fe'        , 'Albuquerque'      -- NM
             ,'Albany'          , 'New York'         -- NY
             ,'Bismarck'        , 'Fargo'            -- ND
             ,'Saipan'          , 'San Jose'         -- MP
             ,'Columbus'        , 'Cincinnati'       -- OH
             ,'Oklahoma City'   , 'Tulsa'            -- OK
             ,'Salem'           , 'Bend'             -- OR
             ,'Harrisburg'      , 'Philadelphia'     -- PA
             ,'San Juan'        , 'Bayamón'          -- PU
             ,'Providence'      , 'Cranston'         -- RI
             ,'Columbia'        , 'Charleston'       -- SC
             ,'Pierre'          , 'Sioux Falls'      -- SD
             ,'Nashville'       , 'Memphis'          -- TN
             ,'Austin'          , 'Houston'          -- TX
             ,'Salt Lake City'  , 'West Valley City' -- UT
             ,'Montpelier'      , 'Burlington'       -- VT
             ,'Charlotte Amalie', 'St Croix'         -- VI
             ,'Richmond'        , 'Virginia Beach'   -- VA
             ,'Olympia'         , 'Seattle'          -- WA
             ,'Charleston'      , 'Huntington'       -- WV
             ,'Madison'         , 'Milwaukeee'       -- WI
             ,'Cheyenne'        , 'Casper'           -- WY
           ) -> (random() * 109)::int
         END city
    FROM ADD_REGION_RELID d
    JOIN tables.country c
      ON c.relid = d.country_relid
)
-- SELECT * FROM ADD_CITY;
--  type_relid | country_relid | num_regions | min_region_relid | region_relid |        city        
-- ------------+---------------+-------------+------------------+--------------+--------------------
--             |             2 |          13 |                1 |            4 | "Winnepeg"
--             |             2 |          13 |                1 |            1 | "Moncton"
--           1 |             3 |             |                  |              | "Flying Fish Cove"
--           3 |             3 |             |                  |              | "Flying Fish Cove"
--             |             4 |          55 |               14 |           21 | "Salem"
-- (5 rows)

, ADD_ADDRESS AS (
  SELECT d.*
        ,CASE c.code_2
         WHEN 'AW' THEN
           jsonb_build_array(
              'Bilderdijkstraat'
             ,'Caya Papa Juan Pablo II'
             ,'Dominicanessenstraat'
             ,'Watty Vos Blvd'
             ,'Patiastraat'
           ) -> (random() * 4)::int
         WHEN 'CA' THEN
           jsonb_build_array(
              'Argyle St'
             ,'Campbell Rd'
             ,'Cariboo Rd'
             ,'George St'
             ,'Granville St'
             ,'Jasper Ave'
             ,'Osborne St'
             ,'Portage Ave'
             ,'Robson St'
             ,'Rue du Petit-Champlain'
             ,'Saint Laurent Boulevard'
             ,'Second St'
             ,'Sussex Drive'
             ,'Stephen Ave'
             ,'Water St'
             ,'Yonge St'
           ) -> (random() * 15)::int
         WHEN 'CX' THEN
           jsonb_build_array(
              'Abbots Nest'
             ,'Hawks Rd'
             ,'Lam Lok Loh'
             ,'Pai Chin Lu'
             ,'Short St'
           ) -> (random() * 4)::int
         WHEN 'US' THEN
           jsonb_build_array(
              '6th St'
             ,'Abbot Kinney Blvd'
             ,'Alamo Square'
             ,'Beale St'
             ,'Bourbon St'
             ,'Calle Ocho'
             ,'East Exchange Ave'
             ,'Fifth Ave'
             ,'Front St'
             ,'Hollywood Blvd'
             ,'Lake Shore Dr'
             ,'Lombard St'
             ,'Melrose Ave'
             ,'Michiagn Ave'
             ,'Newbury St'
             ,'NW 2nd Ave'
             ,'Ocean Dr'
             ,'Rodeo Dr'
             ,'Santana Row'
             ,'Sesame St'
             ,'The Strip'
           ) -> (random() * 20)::int
         END address
    FROM ADD_CITY d
    JOIN tables.country c
      ON c.relid = d.country_relid
)
-- SELECT * FROM ADD_ADDRESS;
--  type_relid | country_relid | num_regions | min_region_relid | region_relid |        city        |    address     
-- ------------+---------------+-------------+------------------+--------------+--------------------+----------------
--           1 |             2 |          13 |                1 |            3 | "Regina"           | "Granville St"
--             |             3 |             |                  |              | "Drimsite"         | "Short St"
--             |             3 |             |                  |              | "Drimsite"         | "Short St"
--             |             3 |             |                  |              | "Flying Fish Cove" | "Pai Chin Lu"
--           2 |             4 |          55 |               14 |           65 | "Fort Wayne"       | "Beale St"
-- (5 rows)

, ADD_MAILING_CODE AS (
  SELECT d.*
        ,CASE c.code_2
         WHEN 'CA' THEN -- Canada
           chr(ascii('A') + (random() * 25)::int) || -- letter
           chr(ascii('0') + (random() *  9)::int) || -- digit
           chr(ascii('A') + (random() * 25)::int) || -- letter
           ' '                                    || -- space
           chr(ascii('0') + (random() *  9)::int) || -- digit
           chr(ascii('A') + (random() * 25)::int) || -- letter
           chr(ascii('0') + (random() *  9)::int)    -- digit
         WHEN 'CX' THEN -- Christmas Island
           '6798'
         WHEN 'US' THEN -- US
           --- Start with 5 digits
           chr(ascii('0') + (random() * 9)::int) ||
           chr(ascii('0') + (random() * 9)::int) ||
           chr(ascii('0') + (random() * 9)::int) ||
           chr(ascii('0') + (random() * 9)::int) ||
           chr(ascii('0') + (random() * 9)::int) ||
           -- Randomly add a dash and 4 digits for plus 4
           CASE random() < 0.5
           WHEN TRUE THEN
             ''
           ELSE
             '-'                                   ||
             chr(ascii('0') + (random() * 9)::int) ||
             chr(ascii('0') + (random() * 9)::int) ||
             chr(ascii('0') + (random() * 9)::int) ||
             chr(ascii('0') + (random() * 9)::int)
           END
         END mailing_code
    FROM ADD_ADDRESS d
    JOIN tables.country c
      ON c.relid = d.country_relid
    LEFT
    JOIN tables.region  r
      ON r.country_relid = c.relid
     AND r.relid = d.region_relid
)
-- SELECT * FROM ADD_MAILING_CODE;
--  type_relid | country_relid | num_regions | min_region_relid | region_relid |     city      |        address         | mailing_code 
-- ------------+---------------+-------------+------------------+--------------+---------------+------------------------+--------------
--           3 |             1 |             |                  |              | "Cunucu Abao" | "Dominicanessenstraat" | 
--           2 |             2 |          13 |                1 |            4 | "Brandon"     | "Cariboo Rd"           | T3Y 3X6
--           2 |             3 |             |                  |              | "Poon Saan"   | "Pai Chin Lu"          | 6798
--           1 |             3 |             |                  |              | "Drimsite"    | "Pai Chin Lu"          | 6798
--           2 |             4 |          55 |               14 |           38 | "Omaha"       | "East Exchange Ave"    | 14650
-- (5 rows)

, GEN_ADDRESS AS (
  SELECT row_number() OVER() AS relid
        ,d.type_relid AS type_relid
        ,d.country_relid
        ,d.region_relid
        ,gen_random_uuid()    AS id
        ,1                    AS version
        ,current_timestamp    AS created
        ,current_timestamp    AS changed
        ,d.city
        ,d.address            AS address
        ,CASE WHEN d.type_relid IS NOT NULL THEN 'Door 5' END AS address_2
        ,CASE WHEN (d.type_relid IS NOT NULL) AND (random() < 0.5) THEN 'Stop 6' END AS address_3
        ,d.mailing_code
        ,row_number() OVER(PARTITION BY d.type_relid IS NULL) person_business_relid
    FROM ADD_MAILING_CODE d
)
SELECT * FROM GEN_ADDRESS;
--  relid | type_relid | country_relid | region_relid |                  id                  | version |            created            |            changed            |     city      |          address          | address_2 | address_3 | mailing_code 
-- -------+------------+---------------+--------------+--------------------------------------+---------+-------------------------------+-------------------------------+---------------+---------------------------+-----------+-----------+--------------
--      1 |          3 |             1 |              | f2eea31f-481c-49c8-a968-17f3db1a016b |       1 | 2024-07-24 11:56:38.769804+00 | 2024-07-24 11:56:38.769804+00 | "Cunucu Abao" | "Caya Papa Juan Pablo II" | Door 5    | Stop 6    | 
--      2 |            |             1 |              | 003ec98d-4668-4ab5-a34b-7635deecd083 |       1 | 2024-07-24 11:56:38.769804+00 | 2024-07-24 11:56:38.769804+00 | "Bubali"      | "Caya Papa Juan Pablo II" |           |           | 
--      3 |          1 |             2 |            6 | 337f9e9c-d59a-4a56-8d9c-ab6dcb7fda8e |       1 | 2024-07-24 11:56:38.769804+00 | 2024-07-24 11:56:38.769804+00 | "Toronto"     | "Water St"                | Door 5    | Stop 6    | Y1J 3S6
--      4 |          2 |             3 |              | cfad66b2-35b1-47df-bb91-e2e23542818a |       1 | 2024-07-24 11:56:38.769804+00 | 2024-07-24 11:56:38.769804+00 | "Poon Saan"   | "Pai Chin Lu"             | Door 5    | Stop 6    | 6798
--      5 |            |             4 |           49 | 7d1c9ead-d4f4-4eec-a597-026d9c6985db |       1 | 2024-07-24 11:56:38.769804+00 | 2024-07-24 11:56:38.769804+00 | "Newark"      | "Calle Ocho"              |           |           | 95714-5848
-- (5 rows)

, MOD_PERSON_BUSINESS_RELIDS AS (
  SELECT d.relid
        ,d.type_relid
        ,d.country_relid
        ,d.region_relid
        ,d.id
        ,d.version
        ,d.created
        ,d.changed
        ,d.city
        ,d.address
        ,d.address_2
        ,d.address_3
        ,d.mailing_code
        ,CASE WHEN d.type_relid IS NOT NULL THEN D.person_business_relid END AS person_business_relid
    FROM GEN_ADDRESS d
)
SELECT * FROM ADD_PERSON_BUSINESS_RELIDS;

-- Insert addresses and return generated relids
, INS_ADDRESS AS (
     INSERT
       INTO tables.address(
               type_relid
              ,country_relid
              ,region_relid
              ,id
              ,version
              ,created
              ,changed
              ,city
              ,address
              ,address_2
              ,address_3
              ,mailing_code
            )
     SELECT type_relid
           ,country_relid
           ,region_relid
           ,id
           ,version
           ,created
           ,changed
           ,city
           ,address
           ,address_2
           ,address_3
           ,mailing_code
       FROM GEN_ADDRESS
  RETURNING relid
)
-- SELECT * FROM INS_ADDRESS;
--  relid 
-- -------
--      1
--      2
--      3
-- ...

-- Insert person customers and return generated relids
, INS_CUSTOMER_PERSON AS (
     INSERT
       INTO tables.customer_person(
               address_relid
              ,id
              ,version
              ,created
              ,changed
              ,first_name
              ,middle_name
              ,last_name
            )
     SELECT relid
           ,gen_random_uuid()
           ,1
           ,current_timestamp
           ,current_timestamp
           ,'John'
           ,'James'
           ,'Doe'
       FROM GEN_ADDRESS
      WHERE address_2 IS NULL
  RETURNING relid
)
-- SELECT * FROM INS_CUSTOMER_PERSON;
--  relid 
-- -------
--      1
--      2
--      3
-- ...

-- Insert business customers and return generated relids
, INS_CUSTOMER_BUSINESS AS (
     INSERT
       INTO tables.customer_business(
               id
              ,version
              ,created
              ,changed
              ,name
            )
     SELECT gen_random_uuid()
           ,1
           ,current_timestamp
           ,current_timestamp
           ,'Biz'
       FROM GEN_ADDRESS
      WHERE address_2 IS NOT NULL
  RETURNING relid
)
-- SELECT * FROM INS_CUSTOMER_BUSINESS;
--  relid 
-- -------
--      1
--      2
--      3
--      4
--      5
-- (5 rows)

-- Insert join entries for business customer addresses
, INS_CUSTOMER_BUSINESS_ADDRESS_JT AS (
     INSERT
       INTO tables.customer_business_address_jt(
               business_relid
              ,address_relid
            )
     SELECT cbus.relid
           ,addr.relid
       FROM GEN_ADDRESS
      WHERE address_2 IS NOT NULL
)
SELECT *
  FROM INS_ADDRESS
 UNION ALL
SELECT *
  FROM INS_CUSTOMER_PERSON
 UNION ALL
SELECT *
  FROM INS_CUSTOMER_BUSINESS
 UNION ALL
SELECT *
  FROM INS_CUSTOMER_BUSINESS_ADDRESS_JT;
