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

-- Add {st: street, cn: city, mcp: mailing code prefix (optional)} object for chosen city/region
, ADD_CITY_STREET AS (
  SELECT d.*
        ,CASE c.code_2
         WHEN 'AW' THEN -- Aruba
           jsonb_build_array(
              jsonb_build_object(
                 'st'
                ,'Caya Frans Figaroa'
                ,'cn'
                ,'Noord'
              )
             ,jsonb_build_object(
                 'st'
                ,'Spinozastraat'
                ,'cn'
                ,'Oranjestad'
              )
             ,jsonb_build_object(
                 'st'
                ,'Bloemond'
                ,'cn'
                ,'Paradera'
              )
             ,jsonb_build_object(
                 'st'
                ,'Sero Colorado'
                ,'cn'
                ,'San Nicolas'
              )
             ,jsonb_build_object(
                 'st'
                ,'San Fuego'
                ,'cn'
                ,'Santa Cruz'
              )
           ) -> (random() * 4)::int
         WHEN 'CA' THEN -- Canada
           CASE r.code
           WHEN 'AB' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'17th Ave SW'
                  ,'cn'
                  ,'Calgary'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Whyte Ave'
                  ,'cn'
                  ,'Edmonton'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'T')
           END
           WHEN 'BC' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Government St'
                  ,'cn'
                  ,'Victoria'
                )
               ,jsonb_build_array(
                   'st'
                   ,'Robson St'
                   ,'cn'
                  ,'Vancouver'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'V')
           END
           WHEN 'MB' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Regent Ave W'
                  ,'cn' 
                  ,'Winnipeg'
                )
               ,jsonb_build_array(
                   'st'
                  ,'Rosser Ave'
                  ,'cn'
                  ,'Brandon'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'R')
           END
           WHEN 'NB' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Dundonald St'
                  ,'cn'
                  ,'Fredericton'
                )
               ,jsonb_build_object(
                   'st'
                  ,'King St'
                  ,'cn'
                  ,'Moncton'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'E')
           END
           WHEN 'NL' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'George St'
                  ,'cn'
                  ,'St John''s'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Everest St'
                  ,'cn'
                  ,'Paradise'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'A')
           END
           WHEN 'NT' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Ragged Ass Rd'
                  ,'cn'
                  ,'Yellowknife'
                )
               ,jsonb_build_object(
                   'st'
                   ,'Poplar Rd'
                   ,'cn'
                  ,'Hay River'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'X')
           END
           WHEN 'NS' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Spring Garden Rd'
                  ,'cn'
                  ,'Halifax'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Dorchester St'
                  ,'cn'
                  ,'Sydney'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'B')
           END
           WHEN 'NU' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Mivvik St'
                  ,'cn' 
                  ,'Iqaluit'
                )
               ,jsonb_build_object(
                   'st'
                  ,'TikTaq Ave'
                  ,'cn'
                  ,'Rankin Inlet'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'X')
           END
           WHEN 'ON' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Wellington St'
                  ,'cn'
                  ,'Ottawa'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Yonge St'
                  ,'cn'
                  ,'Toronto'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     json_build_array('K', 'L', 'M', 'N', 'P') -> (random() * 4)::int
                  )
           END
           WHEN 'PE' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Richmond St'
                  ,'cn'
                  ,'Charlottetown'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Water St'
                  ,'cn'
                  ,'Summerside'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'C')
           END
           WHEN 'QC' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Petit-Champlain St'
                  ,'cn'
                  ,'Quebec City'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Sainte-Catherine St'
                  ,'cn'
                  ,'Montreal'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     json_build_array('G', 'H', 'J') -> (random() * 2)::int
                  )
           END
           WHEN 'SK' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Broadway Ave'
                  ,'cn'
                  ,'Saskatoon'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Winnipeg St'
                  ,'cn'
                  ,'Regina'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'S')
           END
           WHEN 'YT' THEN
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Saloon Rd'
                  ,'cn'
                  ,'Whitehorse'
                )
               ,jsonb_build_object(
                   'st'
                  ,'4th Ave'
                  ,'cn'
                  ,'Dawson City'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'Y')
           END
         END
         WHEN 'CX' THEN -- Christmas Island
           jsonb_build_array(
              jsonb_build_object(
                 'st'
                ,'Lam Lok Loh'
                ,'cn'
                ,'Drumsite'
              )
             ,jsonb_build_object(
                 'st'
                ,'Jln Pantai'
                ,'cn'
                ,'Flying Fish Cove'
              )
             ,jsonb_build_object(
                 'st'
                ,'San Chye Loh'
                ,'cn'
                ,'Poon Saan'
              )
             ,jsonb_build_object(
                 'st'
                ,'Sea View Dr'
                ,'cn'
                ,'Silver City'
              )
           ) -> (random() * 3)::int
         END
         WHEN 'US' THEN -- United States
           CASE r.code
           WHEN 'AL' THEN -- Alabama
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Dexter Ave'
                  ,'cn'
                  ,'Montgomery'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Huntsville'
                  ,'cn'
                  ,'Holmes Ave NW'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (SELECT jsonb_agg(v::text)
                       FROM (
                               SELECT generate_series(350, 369) v
                               EXCEPT
                               SELECT 353
                            ) t
                     ) -> (random() * (369 - 350 - 1))::int
                  )
           END
           WHEN 'AK' THEN -- Alaska
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'South Franklin St'
                  ,'cn'
                  ,'Juneau'
                )
               ,jsonb_build_object(
                   'st'
                  ,'2nd Ave'
                  ,'cn'
                  ,'Fairbanks'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (995 + (random() * (999 - 995))::int)::text
                  
           END
           WHEN 'AS' THEN -- American Samoa
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Route 011'
                  ,'cn'
                  ,'American Samoa, Eastern District, Vaifanua County, Faalefu'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Mason Gelns'
                  ,'cn'
                  ,'American Samoa, Western District, Leasina County, Aasu, A''asu'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     '96799'
                  )
           END
           WHEN 'AZ' THEN -- Arizona
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Van Buren St'
                  ,'cn'
                  ,'Phoenix'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Fourth Ave'
                  ,'cn'
                  ,'Tucson'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (SELECT jsonb_agg(v::text)
                       FROM (
                               SELECT generate_series(850, 865) v
                               EXCEPT
                               SELECT jsonb_array_elements(jsonb_build_array(854, 858, 861, 862))::int
                            ) t
                     ) -> (random() * (865 - 850 - 4)::int
                  )
           END
           WHEN 'AR' THEN -- Arkansas
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Commerce St'
                  ,'cn'
                  ,'Little Rock'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Dickson St'
                  ,'cn'
                  ,'Fayetteville'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (716 + (random() * (729 - 716))::int)::text
                  )
           END
           WHEN 'CA' THEN -- California
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'K St'
                  ,'cn'
                  ,'Sacramento'
                )
               ,jsonb_build_object(
                   'st'
                  ,'San Diego Ave'
                  ,'cn'
                  ,'San Diego'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (SELECT jsonb_agg(v::text)
                       FROM (
                               SELECT generate_series(900, 961) v
                               EXCEPT
                               SELECT jsonb_array_elements(jsonb_build_array(909, 929, 938))::int
                            ) t
                     ) -> (random() * (961 - 900 - 3))::int
                  )
           END
           WHEN 'CO' -- Colorado
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'East Colfax Ave'
                  ,'cn'
                  ,'Denver'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Wilcox St'
                  ,'cn'
                  ,'Castle Rock'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (800 + (random() * (816 - 800))::int)::text
                  )
           END
           WHEN 'CT' -- Connecticut
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Pratt St'
                  ,'cn'
                  ,'Hartford'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Helen St'
                  ,'cn'
                  ,'Bridgeport'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     "0" || (60 + (random() * (69 - 60))::int)::text
                  )
           END
           WHEN 'DC' -- District of Columbia
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Pennsylvania Ave'
                  ,'cn'
                  ,'Washington'
                )
               ,jsonb_build_object(
                   'st'
                  ,'7th St'
                  ,'cn'
                  ,'Shaw'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (SELECT jsonb_agg(v::text)
                       FROM (
                               SELECT generate_series(200, 205) v
                               EXCEPT
                               SELECT 201
                            ) t
                     ) -> (random() * (205 - 200 - 1))::int
           END
           WHEN 'DE' -- Delaware
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Division St'
                  ,'cn'
                  ,'Dover'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Market St'
                  ,'cn'
                  ,'Wilington'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (197 + (random() * (199 - 197))::int)::text
                  )
           END
           WHEN 'FL' -- Florida
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Monroe St'
                  ,'cn'
                  ,'Tallahassee'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Laura St'
                  ,'cn'
                  ,'Jacksonville'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (SELECT jsonb_agg(v::text)
                       FROM (
                               SELECT generate_series(320, 349) v
                               EXCEPT
                               SELECT jsonb_array_elements(jsonb_build_array(340, 343, 345, 348))::int
                            ) t
                     ) -> (random() * (349 - 320 - 4))::int
                  )
           END
           WHEN 'GA' -- Georgia
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Peachtree St'
                  ,'cn'
                  ,'Atlanta'
                )
               ,jsonb_build_object(
                   'st'
                  ,'11th St'
                  ,'cn'
                  ,'Columbus'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (SELECT jsonb_agg(v::text)
                       FROM (
                               SELECT generate_series(300, 319) v
                                UNION ALL
                               SELECT generate_series(398, 399)
                            ) t
                     ) -> (random() * (319 - 300 + 2))::int
                  )
           END
           WHEN 'GU' -- Guam
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Marine Corps Dr'
                  ,'cn'
                  ,'Hagåtña'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Buena Vista Ave'
                  ,'cn'
                  ,'Dededo'
                )
             ) -> random()::int ||
                  jsonb_build_object('mcp', '959')
           END
           WHEN 'HI' -- Hawaii
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Kalakaua Ave'
                  ,'cn'
                  ,'Honolulu'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Banyan Dr'
                  ,'cn'
                  ,'Hilo'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     "0" || (967 + (random() * (968 - 967))::int)::text
                  )
           END
           WHEN 'ID' -- Idaho
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Capitol Blvd'
                  ,'cn'
                  ,'Boise'
                )
               ,jsonb_build_object(
                   'st'
                  ,'E Pine Ave'
                  ,'cn'
                  ,'Meridian'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     "0" || (832 + (random() * (838 - 832))::int)::text
                  )
           END
           WHEN 'IL' THEN -- Illinois
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Route 66'
                  ,'cn'
                  ,'Springfield'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Michigan Ave'
                  ,'cn'
                  ,'Chicago'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (SELECT jsonb_agg(v::text)
                       FROM (
                               SELECT generate_series(600, 629) v
                               EXCEPT
                               SELECT 621
                            ) t
                     ) -> (random() * (629 - 600 - 1))::int
                  )
           END
           
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
