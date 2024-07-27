-- Seed addresses

-- Parameters for seeding
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

-- Multiply the one params row by the num_rows value
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

-- Generate a new data set with random address type relids and random country relids
-- If a random type relid is 0, change it to null, as it represents a person address, and type relids are only for
-- business addresses
, GEN_ADDRESS_COUNTRY_RELID AS (
  SELECT NULLIF((random() * d.num_address_types)::int, 0)      type_relid
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

-- Add number of regions for the chosen counntry, and minimum region relid
-- Region relid is a bit tricky:
-- country 1 region relids start at 1
-- country 2 region relids start at (max relid for country 1) + 1
-- country 3 region relids start at (max relid for country 2) + 1
-- provide minimum region relid for each randomly chosen country, which is null if the country has no regions
-- Both number of regions and minimum region relid are null for countries with no regions
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

-- Add a region relid
-- pick a random number from 0 to num_regions - 1
-- add min_region_relid for the country
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

-- Add (street, city) array that exists within chosen region
, ADD_CITY_STREET AS (
  SELECT d.*
        ,CASE c.code_2
         WHEN 'AW' THEN -- Aruba
           jsonb_build_array(
              jsonb_build_array(
                 'Caya Frans Figaroa'
                ,'Noord'
              )
             ,jsonb_build_array(
                 'Spinozastraat'
                ,'Oranjestad'
              )
             ,jsonb_build_array(
                 'Bloemond'
                ,'Paradera'
              )
             ,jsonb_build_array(
                 'Sero Colorado'
                ,'San Nicolas'
              )
             ,jsonb_build_array(
                 'San Fuego'
                ,'Santa Cruz'
              )
           ) -> (random() * 4)::int
         WHEN 'CA' THEN -- Canada
           CASE r.code
           WHEN 'AB' THEN
             jsonb_build_array(
                jsonb_build_array(
                   '17th Ave SW'
                  ,'Calgary'
                )
               ,jsonb_build_array(
                   'Whyte Ave'
                  ,'Edmonton'
                )
             )
           WHEN 'BC' then
             jsonb_build_array(
                jsonb_build_array(
                   'Government St'
                  ,'Victoria'
                )
               ,jsonb_build_array(
                   'Robson St'
                  ,'Vancouver'
                )
             )
           WHEN 'MB' then
             jsonb_build_array(
                jsonb_build_array(
                   'Regent Ave W'
                  ,'Winnipeg'
                )
               ,jsonb_build_array(
                   'Rosser Ave'
                  ,'Brandon'
                )
             )
           WHEN 'NB' then
             jsonb_build_array(
                jsonb_build_array(
                   'Dundonald St'
                  ,'Fredericton'
                )
               ,jsonb_build_array(
                   'King St'
                  ,'Moncton'
                )
             )
           WHEN 'NL' then
             jsonb_build_array(
                jsonb_build_array(
                   'George St'
                  ,'St John''s'
                )
               ,jsonb_build_array(
                   'Everest St'
                  ,'Paradise'
                )
             )
           WHEN 'NT' then
             jsonb_build_array(
                jsonb_build_array(
                   'Ragged Ass Rd'
                  ,'Yellowknife'
                )
               ,jsonb_build_array(
                   'Poplar Rd'
                  ,'Hay River'
                )
             )
           WHEN 'NS' then
             jsonb_build_array(
                jsonb_build_array(
                   'Spring Garden Rd'
                  ,'Halifax'
                )
               ,jsonb_build_array(
                   'Dorchester St'
                  ,'Sydney'
                )
             )
           WHEN 'NU' then
             jsonb_build_array(
                jsonb_build_array(
                   'Mivvik St'
                  ,'Iqaluit'
                )
               ,jsonb_build_array(
                   'TikTaq Ave'
                  ,'Rankin Inlet'
                )
             )
           WHEN 'ON' then
             jsonb_build_array(
                jsonb_build_array(
                   'Wellington St'
                  ,'Ottawa'
                )
               ,jsonb_build_array(
                   'Yonge St'
                  ,'Toronto'
                )
             )
           WHEN 'PE' then
             jsonb_build_array(
                jsonb_build_array(
                   'Richmond St'
                  ,'Charlottetown'
                )
               ,jsonb_build_array(
                   'Water St'
                  ,'Summerside'
                )
             )
           WHEN 'QC' then
             jsonb_build_array(
                jsonb_build_array(
                   'Petit-Champlain St'
                  ,'Quebec City'
                )
               ,jsonb_build_array(
                   'Sainte-Catherine St'
                  ,'Montreal'
                )
             )
           WHEN 'SK' then
             jsonb_build_array(
                jsonb_build_array(
                   'Broadway Ave'
                  ,'Saskatoon'
                )
               ,jsonb_build_array(
                   'Winnipeg St'
                  ,'Regina'
                )
             )
           WHEN 'YT' then
             jsonb_build_array(
                jsonb_build_array(
                   'Saloon Rd'
                  ,'Whitehorse'
                )
               ,jsonb_build_array(
                   '4th Ave'
                  ,'Dawson City'
                )
             )
           END -> random()::int
         WHEN 'CX' THEN -- Christmas Island
           jsonb_build_array(
              jsonb_build_array(
                 'Lam Lok Loh'
                ,'Drumsite'
              )
             ,jsonb_build_array(
                 'Jln Pantai'
                ,'Flying Fish Cove'
              )
             ,jsonb_build_array(
                 'San Chye Loh'
                ,'Poon Saan'
              )
             ,jsonb_build_array(
                 'Sea View Dr'
                ,'Silver City'
              )
           ) -> (random() * 3)::int
         WHEN 'US' THEN -- United States
           -- Postgres has limit of 100 function args, and we have 55 regions = 110 args to jsonb_build_object
           -- Use two jsonb_build_objects for 30 and 25 regions, using || to merge them into one object 
           jsonb_build_object(
              'AL', jsonb_build_array(
                'Montgomery'      , 'Birmingham'
              )
             ,'AK', jsonb_build_array(
                'Juneau'          , 'Fairbanks'
              )
             ,'AS', jsonb_build_array(
                'Aunu''u'         , 'Ofu'
              )
             ,'AZ', jsonb_build_array(
                'Phoenix'         , 'Tucson'
              )
             ,'AR', jsonb_build_array(
                'Little Rock'     , 'Fayetteville'
              )
             ,'CA', jsonb_build_array(
                'Sacramento'      , 'San Diego'
              )
             ,'CO', jsonb_build_array(
                'Denver'          , 'Castle Rock'
              )
             ,'CT', jsonb_build_array(
                'Hartford'        , 'Bridgeport'
              )
             ,'DE', jsonb_build_array(
                'Dover'           , 'Wilmington'
              )
             ,'DC', jsonb_build_array(
                'Washington'      , 'Shaw'
              )
             ,'FL', jsonb_build_array(
                'Tallahassee'     , 'Jacksonville'
              )
             ,'GA', jsonb_build_array(
                'Atlanta'         , 'Columbus'
              )
             ,'GU', jsonb_build_array(
                'Hagåtña'         , 'Dededo'
              )
             ,'HI', jsonb_build_array(
                'Honolulu'        , 'Hilo'
              )
             ,'ID', jsonb_build_array(
                'Boise'           , 'Meridian'
              )
             ,'IL', jsonb_build_array(
                'Springfield'     , 'Chicago'
              )
             ,'IN', jsonb_build_array(
                'Indianapolis'    , 'Fort Wayne'
              )
             ,'IA', jsonb_build_array(
                'Des Moines'      , 'Cedar Rapids'
              )
             ,'KS', jsonb_build_array(
                'Topeka'          , 'Wichita'
              )
             ,'KY', jsonb_build_array(
                'Frankfort'       , 'Louisville'
              )
             ,'LA', jsonb_build_array(
                'Baton Rouge'     , 'New Orleans'
              )
             ,'ME', jsonb_build_array(
                'Augusta'         , 'Portland'
              )
             ,'MD', jsonb_build_array(
                'Annapolis'       , 'Baltimore'
              )
             ,'MA', jsonb_build_array(
                'Boston'          , 'Worcester'
              )
             ,'MI', jsonb_build_array(
                'Lansing'         , 'Detroit'
              )
             ,'MN', jsonb_build_array(
                'Saint Paul'      , 'Minneapolis'
              )
             ,'MS', jsonb_build_array(
                'Jackson'         , 'Gulfport'
              )
             ,'MO', jsonb_build_array(
                'Jefferson'       , 'Kansas'
              )
             ,'MT', jsonb_build_array(
                'Helena'          , 'Billings'
              )
             ,'NE', jsonb_build_array(
                'Lincoln'         , 'Omaha'
              )
           ) || jsonb_build_object(
              'NV', jsonb_build_array(
                'Carson City'     , 'Las Vegas'
              )
             ,'NH', jsonb_build_array(
                'Concord'         , 'Manchester'
              )
             ,'NJ', jsonb_build_array(
                'Trenton'         , 'Newark'
              )
             ,'NM', jsonb_build_array(
                'Santa Fe'        , 'Albuquerque'
              )
             ,'NY', jsonb_build_array(
                'Albany'          , 'New York'
              )
             ,'ND', jsonb_build_array(
                'Bismarck'        , 'Fargo'
              )
             ,'MP', jsonb_build_array(
                'Saipan'          , 'San Jose'
              )
             ,'OH', jsonb_build_array(
                'Columbus'        , 'Cincinnati'
              )
             ,'OK', jsonb_build_array(
                'Oklahoma City'   , 'Tulsa'
              )
             ,'OR', jsonb_build_array(
                'Salem'           , 'Bend'
              )
             ,'PA', jsonb_build_array(
                'Harrisburg'      , 'Philadelphia'
              )
             ,'PU', jsonb_build_array(
                'San Juan'        , 'Bayamón'
              )
             ,'RI', jsonb_build_array(
                'Providence'      , 'Cranston'
              )
             ,'SC', jsonb_build_array(
                'Columbia'        , 'Charleston'
              )
             ,'SD', jsonb_build_array(
                'Pierre'          , 'Sioux Falls'
              )
             ,'TN', jsonb_build_array(
                'Nashville'       , 'Memphis'
              )
             ,'TX', jsonb_build_array(
                'Austin'          , 'Houston'
              )
             ,'UT', jsonb_build_array(
                'Salt Lake City'  , 'West Valley City'
              )
             ,'VT', jsonb_build_array(
                'Montpelier'      , 'Burlington'
              )
             ,'VI', jsonb_build_array(
                'Charlotte Amalie', 'St Croix'
              )
             ,'VA', jsonb_build_array(
                'Richmond'        , 'Virginia Beach'
              )
             ,'WA', jsonb_build_array(
                'Olympia'         , 'Seattle'
              )
             ,'WV', jsonb_build_array(
                'Charleston'      , 'Huntington'
              )
             ,'WI', jsonb_build_array(
                'Madison'         , 'Milwaukeee'
              )
             ,'WY', jsonb_build_array(
                'Cheyenne'        , 'Casper'
              )
           ) -> r.code -> random()::int
         END city
    FROM ADD_REGION_RELID d
    JOIN tables.country c
      ON c.relid = d.country_relid
    LEFT
    JOIN tables.region r
      ON r.relid = d.region_relid
)
-- SELECT * FROM ADD_CITY;
--  type_relid | country_relid | num_regions | min_region_relid | region_relid |        city        
-- ------------+---------------+-------------+------------------+--------------+--------------------
--           2 |             1 |             |                  |              | "Noord"
--           1 |             2 |          13 |                1 |            5 | "St John's"
--           1 |             2 |          13 |                1 |            4 | "Moncton"
--           1 |             3 |             |                  |              | "Flying Fish Cove"
--           2 |             4 |          55 |               14 |           25 | "Atlanta"
-- (5 rows)

, ADD_ADDRESS AS (
  SELECT d.*
         CASE c.code_2
         WHEN 'AW' THEN -- Aruba: street civic city
           jsonb_build_array(
              jsonb_build_array(
                 'Bilderdijkstraat', 'Oranjestad'
              )
             ,jsonb_build_array(
                 'Savaneta', 'Savaneta'
              )
             ,jsonb_build_array(
                 'San Fuego', 'Santa Cruz'
              )
             ,jsonb_build_array(
                 'Caya Sint Maarten', 'San Nicolas'
              )
             ,jsonb_build_array(
                 'Alto Vista', 'Noord'
              )
           )
         WHEN 'CA' THEN -- Canada: civic street city
           json_build_object(
              'AB', jsonb_build_array(
                '17th Ave SW', 'Whyte Ave'
              )
             ,'BC', jsonb_build_array(
                'Government St', 'Robson St'
              )
             ,'MB', jsonb_build_array(
                'Regent Ave W', 'Rosser Ave'
              )
             ,'NB', jsonb_build_array(
                'Dundonald St', 'King St'
              )
             ,'NL', jsonb_build_array(
                'George St', 'Everest St'
              )
             ,'NT', jsonb_build_array(
                'Ragged Ass Rd', 'Poplar Rd'
              )
             ,'NS', jsonb_build_array(
                'Spring Garden Rd', 'Dorchester St'
              )
             ,'NU', jsonb_build_array(
                'Mivvik St', 'TikTaq Ave'
              )
             ,'ON', jsonb_build_array(
                'Wellington Street', 'Yonge Street'
              )
             ,'PE', jsonb_build_array(
                'Richmond St', 'Water St'
              )
             ,'QC', jsonb_build_array(
                'Petit-Champlain St', 'Sainte-Catherine St'
              )
             ,'SK', jsonb_build_array(
                'Broadway Ave', 'Winnipeg St'
              )
             ,'YT', jsonb_build_array(
                'Saloon Rd', '4th Ave'
              )
           ) -> r.code -> random()::int
         WHEN 'CX' THEN -- Christmas Island
           jsonb_build_array(
              'Abbots Nest'
             ,'Hawks Rd'
             ,'Lam Lok Loh'
             ,'Pai Chin Lu'
             ,'Short St'
           ) -> (random() * 4)::int
         WHEN 'US' THEN -- United States
           json_build_object(
              'AL', jsonb_build_array(
                '17th Ave SW', 'Whyte Ave'
              )
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
    LEFT
    JOIN tables.region r
      ON r.relid = d.relid
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
  SELECT d.type_relid AS type_relid
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
    FROM ADD_MAILING_CODE d
   ORDER BY d.type_relid IS NULL
)
-- SELECT * FROM GEN_ADDRESS;
--  type_relid | country_relid | region_relid |                  id                  | version |            created            |            changed            |        city        |         address          | address_2 | address_3 | mailing_code 
-- ------------+---------------+--------------+--------------------------------------+---------+-------------------------------+-------------------------------+--------------------+--------------------------+-----------+-----------+--------------
--           1 |             1 |              | 532a80c1-cd11-4763-9782-d7c9c9b42c9a |       1 | 2024-07-25 11:29:11.124512+00 | 2024-07-25 11:29:11.124512+00 | "Cumana"           | "Watty Vos Blvd"         | Door 5    | Stop 6    | 
--           1 |             2 |           11 | 11c06456-df43-49f5-b947-81d3bbe0dab3 |       1 | 2024-07-25 11:29:11.124512+00 | 2024-07-25 11:29:11.124512+00 | "Yellowknife"      | "Sussex Drive"           | Door 5    | Stop 6    | M6O 2W9
--           3 |             2 |            1 | 9160d6ca-d5dd-4a9e-a512-0629a7a8593c |       1 | 2024-07-25 11:29:11.124512+00 | 2024-07-25 11:29:11.124512+00 | "Winnepeg"         | "Rue du Petit-Champlain" | Door 5    | Stop 6    | G2A 8M8
--           2 |             3 |              | f9dcbaad-a667-4337-8478-3ba149106251 |       1 | 2024-07-25 11:29:11.124512+00 | 2024-07-25 11:29:11.124512+00 | "Silver City"      | "Hawks Rd"               | Door 5    | Stop 6    | 6798
--             |             4 |           46 | 07edc2ec-e166-4ef9-aa61-9e26b3b3b469 |       1 | 2024-07-25 11:29:11.124512+00 | 2024-07-25 11:29:11.124512+00 | "West Valley City" | "Bourbon St"             |           |           | 62983-3972
-- (5 rows)

-- Add a business relid, which is only relevant if the type_relid is not null
, ADD_BUSINESS_RELID AS (
  SELECT d.*
        ,row_number() OVER () AS business_relid
    FROM GEN_ADDRESS d
)
-- SELECT * FROM ADD_BUSINESS_RELID;
--  type_relid | country_relid | region_relid |                  id                  | version |            created            |            changed            |      city      |         address          | address_2 | address_3 | mailing_code | business_relid 
-- ------------+---------------+--------------+--------------------------------------+---------+-------------------------------+-------------------------------+----------------+--------------------------+-----------+-----------+--------------+----------------
--           1 |             1 |              | e89fc7f3-348b-403b-9fef-ae178ee71258 |       1 | 2024-07-25 11:32:13.101516+00 | 2024-07-25 11:32:13.101516+00 | "Moko"         | "Dominicanessenstraat"   | Door 5    | Stop 6    |              |              1
--           1 |             2 |            9 | cb236fdd-800a-402d-9574-045c2372808d |       1 | 2024-07-25 11:32:13.101516+00 | 2024-07-25 11:32:13.101516+00 | "Victoria"     | "Jasper Ave"             | Door 5    | Stop 6    | R6A 8X3      |              2
--           3 |             3 |              | 256c94df-ed59-4277-a681-fd794bec58b0 |       1 | 2024-07-25 11:32:13.101516+00 | 2024-07-25 11:32:13.101516+00 | "Poon Saan"    | "Short St"               | Door 5    | Stop 6    | 6798         |              3
--           1 |             4 |           63 | 008588ff-9b3d-4aa2-9846-a30876bd12a9 |       1 | 2024-07-25 11:32:13.101516+00 | 2024-07-25 11:32:13.101516+00 | "Fayetteville" | "Lombard St"             | Door 5    | Stop 6    | 61326-6247   |              4
--             |             2 |            4 | 557a9d7b-37f6-4685-a7d2-192727d8a1fb |       1 | 2024-07-25 11:32:13.101516+00 | 2024-07-25 11:32:13.101516+00 | "Winnepeg"     | "Rue du Petit-Champlain" |           |           | W3X 3D4      |              5
-- (5 rows)

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
       FROM MOD_PERSON_BUSINESS_RELIDS
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
