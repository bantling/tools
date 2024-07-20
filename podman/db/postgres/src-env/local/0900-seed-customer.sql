-- Seed addresses
WITH PARAMS AS (
  SELECT 100 num_rows
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
  SELECT NULLIF((random() * d.num_address_types)::int, 0)      address_type_relid -- null = person, number = business
        ,      (random() * (d.num_countries     - 1) + 1)::int country_relid
    FROM ADD_ROWS d
)
-- SELECT * FROM GEN_ADDRESS_COUNTRY_RELID;
--  address_type_relid | country_relid 
-- --------------------+---------------
--                   1 |             2
--                   1 |             2
--                     |             1
--                   2 |             3
--                   1 |             1
-- (5 rows)

, ADD_NUM_REGIONS_MIN_RELID AS (
  SELECT d.*
        ,NULLIF((SELECT COUNT(*) FROM tables.region r WHERE r.country_relid = d.country_relid), 0) num_regions
        ,(SELECT MIN(relid) FROM tables.region r WHERE r.country_relid = d.country_relid)          min_region_relid
    FROM GEN_ADDRESS_COUNTRY_RELID d
)
-- SELECT * FROM ADD_NUM_REGIONS_MIN_RELID;
--  address_type_relid | country_relid | num_regions 
-- --------------------+---------------+-------------
--                   2 |             1 |            
--                     |             2 |          13
--                     |             3 |            
--                   2 |             3 |            
--                   2 |             4 |          56
-- (5 rows)

-- region relid is a bit tricky:
-- country 1 region relids start at 1
-- country 2 region relids start at (max relid for country 1) + 1
-- country 3 region relids start at (max relid for country 2) + 1
-- etc
-- pick a random number from 0 to num regions - 1
-- add minimum region relid for the country
, ADD_REGION_RELID AS (
  SELECT d.*
        ,((random() * (d.num_regions - 1)) + d.min_region_relid)::int region_relid
    FROM ADD_NUM_REGIONS_MIN_RELID d
)
-- SELECT * FROM ADD_REGION_RELID;
--  address_type_relid | country_relid | num_regions | region_relid 
-- --------------------+---------------+-------------+--------------
--                   2 |             2 |          13 |            9
--                   2 |             2 |          13 |           11
--                   1 |             3 |             |             
--                   2 |             4 |          56 |           34
--                   2 |             4 |          56 |           12
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
--  address_type_relid | country_relid | num_regions | region_relid |        city        
-- --------------------+---------------+-------------+--------------+--------------------
--                   2 |             1 |             |              | "Barcadera"
--                   2 |             2 |          13 |            5 | "Ottawa"
--                   1 |             3 |             |              | "Drimsite"
--                   1 |             3 |             |              | "Flying Fish Cove"
--                   1 |             3 |             |              | "Poon Saan"
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
--  address_type_relid | country_relid | num_regions | region_relid |        city        |        address         
-- --------------------+---------------+-------------+--------------+--------------------+------------------------
--                   1 |             1 |             |              | "Bubali"           | "Patiastraat"
--                   1 |             1 |             |              | "Bubali"           | "Dominicanessenstraat"
--                   2 |             2 |          13 |           10 | "Rankin Inlet"     | "Portage Ave"
--                   1 |             3 |             |              | "Silver City"      | "Short St"
--                     |             3 |             |              | "Flying Fish Cove" | "Lam Lok Loh"
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
--  address_type_relid | country_relid | num_regions | region_relid |        city        |          address          | mailing_code 
-- --------------------+---------------+-------------+--------------+--------------------+---------------------------+--------------
--                   3 |             1 |             |              | "Cumana"           | "Caya Papa Juan Pablo II" | 
--                     |             2 |          13 |            6 | "Regina"           | "Granville St"            | J3F 5F2
--                   3 |             3 |             |              | "Flying Fish Cove" | "Short St"                | 6798
--                   3 |             3 |             |              | "Drimsite"         | "Abbots Nest"             | 6798
--                   3 |             4 |          55 |           28 | "Sioux Falls"      | "Abbot Kinney Blvd"       | 57876
-- (5 rows)

, GEN_ADDRESS AS (
  SELECT d.address_type_relid AS type_relid
        ,d.country_relid
        ,d.region_relid
        ,gen_random_uuid()    AS id
        ,1                    AS version
        ,current_timestamp    AS created
        ,current_timestamp    AS changed
        ,d.city
        ,d.address            AS address
        ,CASE WHEN d.address_type_relid IS NOT NULL THEN 'Door 5' END AS address_2
        ,CASE WHEN d.address_type_relid IS NOT NULL THEN 'Stop 6' END AS address_3
        ,d.mailing_code
    FROM ADD_MAILING_CODE d
)
-- SELECT * FROM GEN_ADDRESS;
--  type_relid | country_relid | region_relid |                  id                  | version |            created            |            changed            |     city      |          address          | address_2 | address_3 | mailing_code 
-- ------------+---------------+--------------+--------------------------------------+---------+-------------------------------+-------------------------------+---------------+---------------------------+-----------+-----------+--------------
--           2 |             1 |              | 396993e2-66fb-4183-9450-a69cf97fd424 |       1 | 2024-07-20 11:26:11.923622+00 | 2024-07-20 11:26:11.923622+00 | "Oranjestad"  | "Caya Papa Juan Pablo II" | Door 5    | Stop 6    | 
--           1 |             1 |              | 4ab48a16-8287-45f8-b423-36b94260fcef |       1 | 2024-07-20 11:26:11.923622+00 | 2024-07-20 11:26:11.923622+00 | "Moko"        | "Dominicanessenstraat"    | Door 5    | Stop 6    | 
--           2 |             2 |            2 | fbfbeac2-6596-41c8-904c-78c36ee2505f |       1 | 2024-07-20 11:26:11.923622+00 | 2024-07-20 11:26:11.923622+00 | "Regina"      | "Argyle St"               | Door 5    | Stop 6    | I5S 6D7
--             |             3 |              | 7acaa99c-0f92-45f8-9b7f-2aea024839bd |       1 | 2024-07-20 11:26:11.923622+00 | 2024-07-20 11:26:11.923622+00 | "Silver City" | "Abbots Nest"             |           |           | 6798
--           2 |             4 |           13 | 73b95a06-8e8b-41d2-94fd-a537ce364cbb |       1 | 2024-07-20 11:26:11.923622+00 | 2024-07-20 11:26:11.923622+00 | "Austin"      | "Hollywood Blvd"          | Door 5    | Stop 6    | 82067-4225
-- (5 rows)

INSERT INTO tables.address(
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
SELECT *
  FROM GEN_ADDRESS;
