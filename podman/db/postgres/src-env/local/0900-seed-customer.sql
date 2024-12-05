-- Seed addresses

-- Parameters for seeding
-- ${NUM_ROWS} is set as follows:
-- - Makefile has hard-code default of 5
-- - It can be overridden on cli to generate 5,000 rows by invoking "make DB_NUM_CUSTOMERS_GEN=5000 ..."
-- - The Makefile provides this value to Containerfile.in as the build arg DB_NUM_CUSTOMERS_GEN
-- - The Containerfile.in replaces ${NUM_ROWS} in this script with the value of the build arg DB_NUM_CUSTOMERS_GEN
WITH PARAMS AS (
  -- SELECT ${NUM_ROWS} AS NUM_ROWS
  SELECT 5 AS NUM_ROWS
)
 
-- Generate NUM_ROWS rows using generate_series
-- Generate 0 rows if there are already addresses in the system
,INPUT_DATA AS (
   SELECT generate_series(1, NUM_ROWS) AS ix
     FROM PARAMS
    WHERE (SELECT COUNT(*) FROM tables.address) = 0
    ORDER BY 1
)
-- SELECT * FROM INPUT_DATA;
/*
 ix
----
  1
  2
  3
  4
  5
(5 rows)
*/

-- Choose 60% personal addresses and 40% business addresses
,IS_PERSONAL AS (
   SELECT *
          ,random() <= 0.60 AS is_personal
     FROM INPUT_DATA
    ORDER BY 1
)
-- SELECT * FROM IS_PERSONAL;
/*
 ix | is_personal
----+-------------
  1 | t
  2 | t
  3 | f
  4 | t
  5 | t
(5 rows)
*/

-- For personal addresses, choose a null array of address type ids
-- For business addresses, choose a random subset of 1 .. n from all n address type ids
,ADD_ADDRESS_TYPE_IDS AS (
    SELECT *
          ,code.IIF(
              is_personal
             ,NULL
             ,code.JSONB_ARRAY_RANDOM((SELECT jsonb_agg(relid) FROM tables.address_type), 1)
           ) address_type_ids
      FROM IS_PERSONAL
     ORDER BY 1
)
-- SELECT * FROM ADD_ADDRESS_TYPE_IDS;
/*
 ix | is_personal | address_type_ids
----+-------------+------------------
  1 | t           |
  2 | f           | [75]
  3 | t           |
  4 | t           |
  5 | t           |
(5 rows)
*/

-- Add a random country id from all available
,ADD_COUNTRY_ID AS (
    SELECT *
          ,code.JSONB_ARRAY_RANDOM((SELECT jsonb_agg(relid) FROM tables.COUNTRY))::BIGINT country_id
      FROM ADD_ADDRESS_TYPE_IDS
     ORDER BY 1
)
-- SELECT * FROM ADD_COUNTRY_ID;
/*
 ix | is_personal | address_type_ids | country_id
----+-------------+------------------+------------
  1 | t           |                  |          4
  2 | t           |                  |          2
  3 | f           | [75]             |          2
  4 | t           |                  |          1
  5 | t           |                  |          3
(5 rows)
*/

-- Generate a random region id of all regions for the chosen country (null if country has no regions)
,ADD_REGION_ID AS (
    SELECT *
          ,code.JSONB_ARRAY_RANDOM((SELECT jsonb_agg(relid) FROM tables.REGION WHERE country_relid = country_id))::BIGINT region_id
      FROM ADD_COUNTRY_ID
     ORDER BY 1
)
-- SELECT * FROM ADD_REGION_ID;
/*
 ix | is_personal | address_type_ids | country_id | region_id
----+-------------+------------------+------------+-----------
  1 | f           | [75, 76]         |          4 |        21
  2 | t           |                  |          2 |        13
  3 | t           |                  |          2 |         6
  4 | f           | [74]             |          3 |
  5 | t           |                  |          1 |
(5 rows)
*/

-- Add country and region codes
,ADD_COUNTRY_REGION_CODES AS (
    SELECT ari.*
          ,c.code_2 AS country_code
          ,r.code   AS  region_code
      FROM ADD_REGION_ID ari
      JOIN tables.country c
        ON c.relid = ari.country_id
      LEFT
      JOIN tables.region r
        ON r.relid = ari.region_id
     ORDER BY 1
)
-- SELECT * FROM ADD_COUNTRY_REGION_CODES;
/*
 ix | is_personal | address_type_ids | country_id | region_id | country_code | region_code
----+-------------+------------------+------------+-----------+--------------+-------------
  1 | f           | [75, 76, 74]     |          3 |           | CX           |
  2 | t           |                  |          4 |        46 | US           | NV
  3 | t           |                  |          3 |           | CX           |
  4 | f           | [76]             |          2 |        15 | CA           | QC
  5 | t           |                  |          1 |           | AW           |
(5 rows)
*/

-- Add {st: street, cn: city name, mcp: mailing code prefix (optional)} object for chosen country/region 
,ADD_CITY_STREET_MCP AS (
  SELECT acrc.*
        ,CASE country_code
         WHEN 'AW' THEN -- Aruba
           -- select distinct v from (select (
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
           --) v, generate_series(1, 1000) n) t order by 1;
         WHEN 'CA' THEN -- Canada
           CASE region_code
           WHEN 'AB' THEN
             -- select distinct v from (select (
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
             --) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'BC' THEN
             -- select distinct v from (select (
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Government St'
                  ,'cn'
                  ,'Victoria'
                )
               ,jsonb_build_object(
                   'st'
                   ,'Robson St'
                   ,'cn'
                  ,'Vancouver'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'V')
             --) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MB' THEN
             -- select distinct v from (select (
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Regent Ave W'
                  ,'cn' 
                  ,'Winnipeg'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Rosser Ave'
                  ,'cn'
                  ,'Brandon'
                )
             ) -> random()::int || jsonb_build_object('mcp', 'R')
             --) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NB' THEN
             -- select distinct v from (select (
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
             --) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NL' THEN
             -- select distinct v from (select (
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
             --) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NT' THEN
             -- select distinct v from (select (
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
             -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NS' THEN
             -- select distinct v from (select (
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
             -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NU' THEN
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'ON' THEN
               -- select distinct v from (select (
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
                     'mcp'
                    ,jsonb_build_array('K', 'L', 'M', 'N', 'P') -> (random() * 4)::int
                  )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'PE' THEN
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'QC' THEN
               -- select distinct v from (select (
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
                       jsonb_build_array('G', 'H', 'J') -> (random() * 2)::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'SK' THEN
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'YT' THEN
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
          END
         WHEN 'CX' THEN -- Christmas Island
             -- select distinct v from (select (
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
             -- ) v, generate_series(1, 1000) n) t order by 1;
         WHEN 'US' THEN -- United States
           CASE region_code
           WHEN 'AL' THEN -- Alabama
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Dexter Ave'
                    ,'cn'
                    ,'Montgomery'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Holmes Ave NW'
                    ,'cn'
                    ,'Huntsville'
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'AK' THEN -- Alaska
               -- select distinct v from (select (
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
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'AZ' THEN -- Arizona
               -- select distinct v from (select (
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
                       ) -> (random() * (865 - 850 - 4))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'AR' THEN -- Arkansas
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'CA' THEN -- California
               -- select distinct v from (select (
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
                                 SELECT jsonb_array_elements(jsonb_build_array(909, 929))::int
                              ) t
                       ) -> (random() * (961 - 900 - 2))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'CO' THEN -- Colorado
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'CT' THEN -- Connecticut
               -- select distinct v from (select (
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
                         '0' || (60 + (random() * (69 - 60))::int)::text
                      )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'DE' THEN -- Delaware
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'DC' THEN -- District of Columbia
               -- select distinct v from (select (
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
                                  UNION ALL
                                 SELECT 569
                              ) t
                       ) -> (random() * (205 - 200 - 1 + 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'FL' THEN -- Florida
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'GA' THEN -- Georgia
               -- select distinct v from (select (
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
                       ) -> (random() * ((319 - 300) + 2))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'HI' THEN -- Hawaii
               -- select distinct v from (select (
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
                       (967 + random()::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'ID' THEN -- Idaho
               -- select distinct v from (select (
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
                       (832 + (random() * (838 - 832))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'IL' THEN -- Illinois
               -- select distinct v from (select (
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
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'IN' THEN -- Indiana
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Meridian St'
                    ,'cn'
                    ,'Indianapolis'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Calhoun St'
                    ,'cn'
                    ,'Fort Wayne'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (460 + (random() * (479 - 460))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'IA' THEN -- Iowa
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Court Ave'
                    ,'cn'
                    ,'Des Moines'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'First Ave'
                    ,'cn'
                    ,'Cedar Rapids'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(500, 528) v
                                 EXCEPT
                                 SELECT jsonb_array_elements(jsonb_build_array(517, 518, 519))::int
                              ) t
                       ) -> (random() * (528 - 500 - 3))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'KS' THEN -- Kansas
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'SE 10th Ave'
                    ,'cn'
                    ,'Topeka'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'S Hydraulic Ave'
                    ,'cn'
                    ,'Wichita'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(660, 679) v
                                 EXCEPT
                                 SELECT 663
                              ) t
                       ) -> (random() * (679 - 660 - 1))::int
                    )
              -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'KY' THEN -- Kentucky
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Holmes St'
                    ,'cn'
                    ,'Frankfort'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'S Floyd St'
                    ,'cn'
                    ,'Louisville'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(400, 427) v
                                 EXCEPT
                                 SELECT 419
                              ) t
                       ) -> (random() * (427 - 400 - 1))::int
                    )
              -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'LA' THEN -- Louisiana
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Third St'
                    ,'cn'
                    ,'Baton Rouge'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Bourbon St'
                    ,'cn'
                    ,'New Orleans'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(700, 714) v
                                 EXCEPT
                                 SELECT jsonb_array_elements(jsonb_build_array(702, 709))::int
                              ) t
                       ) -> (random() * (714 - 700 - 2))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'ME' THEN -- Maine
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Maine St'
                    ,'cn'
                    ,'Augusta'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Congress St'
                    ,'cn'
                    ,'Portland'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       '0' || (39 + (random() * (49 - 39))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MD' THEN -- Maryland
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Bladen St'
                    ,'cn'
                    ,'Annapolis'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Charles St'
                    ,'cn'
                    ,'Baltimore'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(206, 219) v
                                 EXCEPT
                                 SELECT 213
                              ) t
                       ) -> (random() * (219 - 206 - 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MA' THEN -- Massachusets
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Bladen St'
                    ,'cn'
                    ,'Annapolis'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Charles St'
                    ,'cn'
                    ,'Baltimore'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg('0' || v::text)
                         FROM (
                                 SELECT generate_series(10, 27) v
                                  UNION ALL
                                 SELECT 55
                              ) t
                       ) -> (random() * (27 - 10 + 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MI' THEN -- Michigan
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'W Kalamazoo St'
                    ,'cn'
                    ,'Lansing'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Woodward Ave'
                    ,'cn'
                    ,'Detroit'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (480 + (random() * (499 - 480))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MN' THEN -- Minnesota
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Summit Ave'
                    ,'cn'
                    ,'Saint Paul'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Nicollet Ave'
                    ,'cn'
                    ,'Minneapolis'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(550, 567) v
                                 EXCEPT
                                 SELECT 552
                              ) t
                       ) -> (random() * (567 - 550 - 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MS' THEN -- Mississippi
             -- select distinct v from (select (
             jsonb_build_array(
                jsonb_build_object(
                   'st'
                  ,'Farish St'
                  ,'cn'
                  ,'Jackson'
                )
               ,jsonb_build_object(
                   'st'
                  ,'Seaway Rd'
                  ,'cn'
                  ,'Gulfport'
                )
             ) -> random()::int ||
                  jsonb_build_object(
                     'mcp',
                     (386 + (random() * (397 - 386))::int)::text
                  )
             -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MO' THEN -- Missouri
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Capitol Ave'
                    ,'cn'
                    ,'Jefferson'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Independence Ave'
                    ,'cn'
                    ,'Kansas City'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(630, 658) v
                                 EXCEPT
                                 SELECT jsonb_array_elements(jsonb_build_array(632, 642, 643))::int
                              ) t
                       ) -> (random() * (658 - 630 - 3))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MT' THEN -- Montana
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'E Lyndale Ave'
                    ,'cn'
                    ,'Helena'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Clark Ave'
                    ,'cn'
                    ,'Billings'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (590 + (random() * (599 - 590))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NE' THEN -- Nebraska
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'O St'
                    ,'cn'
                    ,'Lincoln'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Farnam St'
                    ,'cn'
                    ,'Omaha'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(680, 693) v
                                 EXCEPT
                                 SELECT 682
                              ) t
                       ) -> (random() * (693 - 680 - 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NV' THEN -- Nevada
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'E William St'
                    ,'cn'
                    ,'Carson City'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Las Vegas Blvd'
                    ,'cn'
                    ,'Las Vegas'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(889, 898) v
                                 EXCEPT
                                 SELECT jsonb_array_elements(jsonb_build_array(892, 896))::int
                              ) t
                       ) -> (random() * (898 - 889 - 2))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NH' THEN -- New Hampshire
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Loudon Rd'
                    ,'cn'
                    ,'Concord'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Lake Ave'
                    ,'cn'
                    ,'Manchester'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       '0' || (30 + (random() * (38 - 30))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NJ' THEN -- New Jersey
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Front St'
                    ,'cn'
                    ,'Trenton'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Broad St'
                    ,'cn'
                    ,'Newark'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       '0' || (70 + (random() * (89 - 70))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NM' THEN -- New Mexico
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Canyon Rd'
                    ,'cn'
                    ,'Santa Fe'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Central Ave'
                    ,'cn'
                    ,'Albequerque'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(870, 884) v
                                 EXCEPT
                                 SELECT jsonb_array_elements(jsonb_build_array(872, 876))::int
                              ) t
                       ) -> (random() * (884 - 870 - 2))::int
                    )
                -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NY' THEN -- New York
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Lark St'
                    ,'cn'
                    ,'Albany'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Broadway'
                    ,'cn'
                    ,'New York'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v)
                          FROM (
                                  SELECT '005' v
                                   UNION ALL
                                  SELECT generate_series(100, 149)::text
                               ) t
                       ) -> (random() * (149 - 100 + 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'NC' THEN -- North Carolina
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Tapochao Rd'
                    ,'cn'
                    ,'Saipan'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Ayuyu Dr'
                    ,'cn'
                    ,'Marpi'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (270 + (random() * (289 - 270))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'ND' THEN -- North Dakota
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'4th St'
                    ,'cn'
                    ,'Bismarck'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'13th Ave S'
                    ,'cn'
                    ,'Fargo'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (580 + (random() * (588 - 580))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'OH' THEN -- Ohio
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Broad St'
                    ,'cn'
                    ,'Columbus'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Vine St'
                    ,'cn'
                    ,'Cincinnnati'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (430 + (random() * (459 - 430))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'OK' THEN -- Oklahoma
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Reno Ave'
                    ,'cn'
                    ,'Oklahoma City'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'S Zenith ave'
                    ,'cn'
                    ,'Tulsa'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(730, 749) v
                                 EXCEPT
                                 SELECT jsonb_array_elements(jsonb_build_array(732, 733, 742))::int
                              ) t
                       ) -> (random() * (749 - 730 - 3))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'OR' THEN -- Oregon
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Chestnut St'
                    ,'cn'
                    ,'Salem'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Wall St'
                    ,'cn'
                    ,'Bend'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (970 + (random() * (979 - 970))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'PA' THEN -- Pennsylvania
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'State St'
                    ,'cn'
                    ,'Harrisburg'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'South St'
                    ,'cn'
                    ,'Philadelphia'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (150 + (random() * (196 - 150))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'RI' THEN -- Rhode Island
               -- select distinct v from (select (
                 jsonb_build_array(
                    jsonb_build_object(
                       'st'
                      ,'Hope St'
                      ,'cn'
                      ,'Providence'
                    )
                   ,jsonb_build_object(
                       'st'
                      ,'Phenix Ave'
                      ,'cn'
                      ,'Cranston'
                    )
                 ) -> random()::int ||
                      jsonb_build_object(
                         'mcp',
                         '0' || (28 + random()::int)::text
                      )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'SC' THEN -- South Carolina
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Gervais St'
                    ,'cn'
                    ,'Columbia'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'King St'
                    ,'cn'
                    ,'Charleston'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (290 + (random() * (299 - 290))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'SD' THEN -- South Dakota
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'N Taylor Ave'
                    ,'cn'
                    ,'Pierre'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Ladyslipper Cir'
                    ,'cn'
                    ,'Sioux Falls'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (570 + (random() * (577 - 570))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'TN' THEN -- Tennessee
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Edgehill Ave'
                    ,'cn'
                    ,'Nashville'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Spottswood Ave'
                    ,'cn'
                    ,'Memphis'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (370 + (random() * (385 - 370))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'TX' THEN -- Texas
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Sixth St'
                    ,'cn'
                    ,'Austin'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Westheimeer Rd'
                    ,'cn'
                    ,'Houston'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT 733 v
                                  UNION ALL
                                 SELECT generate_series(750, 799)
                                 EXCEPT
                                 SELECT 771
                                  UNION ALL
                                 SELECT 885
                              ) t
                       ) -> (random() * (1 + (799 - 750) - 1 + 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'UT' THEN -- Utah
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Poplar Grove Vlvd S'
                    ,'cn'
                    ,'Salt Lake City'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Nancy Dr'
                    ,'cn'
                    ,'West Valley City'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (840 + (random() * (847 - 840))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'VT' THEN -- Vermont
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Towne Hill Rd'
                    ,'cn'
                    ,'Montpelier'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'N Willard St'
                    ,'cn'
                    ,'Burlington'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg('0' || v::text)
                         FROM (
                                 SELECT generate_series(50, 59) v
                                 EXCEPT
                                 SELECT 55
                              ) t
                       ) -> (random() * (59 - 50 - 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'VA' THEN -- Virginia
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Monument Ave'
                    ,'cn'
                    ,'Richmond'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Atlantic Ave'
                    ,'cn'
                    ,'Virginia Beach'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(220, 246) v
                                  UNION ALL
                                 SELECT 201
                              ) t
                       ) -> (random() * (246 - 220 + 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'WA' THEN -- Washington
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Union Ave SE'
                    ,'cn'
                    ,'Olympia'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Pike St'
                    ,'cn'
                    ,'Seattle'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(980, 994) v
                                 EXCEPT
                                 SELECT 987
                              ) t
                       ) -> (random() * (994 - 980 - 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'WV' THEN -- West Virginia
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Quarrier St'
                    ,'cn'
                    ,'Charleston'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Buffington Ave'
                    ,'cn'
                    ,'Huntington'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (247 + (random() * (268 - 247))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'WI' THEN -- Wisconsin
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'N Bassett St'
                    ,'cn'
                    ,'Madison'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Brady St'
                    ,'cn'
                    ,'Milwaukee'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg(v::text)
                         FROM (
                                 SELECT generate_series(530, 549) v
                                 EXCEPT
                                 SELECT jsonb_array_elements(jsonb_build_array(533, 536))::int
                              ) t
                       ) -> (random() * (549 - 530 - 2))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'WY' THEN -- Wyoming
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Evans Ave'
                    ,'cn'
                    ,'Cheyenne'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'W Collins Dr'
                    ,'cn'
                    ,'Casper'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (820 + (random() * (831 - 820))::int)::text
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'AS' THEN -- American Samoa
               -- select distinct v from (select (
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
                       '967'
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'GU' THEN -- Guam
               -- select distinct v from (select (
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
                    jsonb_build_object('mcp', '969')
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'MP' THEN -- Northern Mariana Islands
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Tapochao Rd'
                    ,'cn'
                    ,'Saipan'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Ayuyu Dr'
                    ,'cn'
                    ,'Marpi'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       '969'
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'PU' THEN -- Puerto Rico
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'C Aragón'
                    ,'cn'
                    ,'San Juan'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Ave Hostos'
                    ,'cn'
                    ,'Bayamón'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       (SELECT jsonb_agg('00' || v::text)
                         FROM (
                                 SELECT generate_series(6, 9) v
                                 EXCEPT
                                 SELECT 8
                              ) t
                       ) -> (random() * (9 - 6 - 1))::int
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
           WHEN 'VI' THEN -- Virgin Islands
               -- select distinct v from (select (
               jsonb_build_array(
                  jsonb_build_object(
                     'st'
                    ,'Harbour Ridge Rd'
                    ,'cn'
                    ,'Charlotte Amalie'
                  )
                 ,jsonb_build_object(
                     'st'
                    ,'Alfred Andrews St'
                    ,'cn'
                    ,'St Croix'
                  )
               ) -> random()::int ||
                    jsonb_build_object(
                       'mcp',
                       '008'
                    )
               -- ) v, generate_series(1, 1000) n) t order by 1;
            END
          END st_city_mcp
    FROM ADD_COUNTRY_REGION_CODES acrc
   ORDER BY 1
)
-- SELECT * FROM ADD_CITY_STREET_MCP;
/*
 ix | is_personal | address_type_ids | country_id | region_id | country_code | region_code |                             st_city_mcp
----+-------------+------------------+------------+-----------+--------------+-------------+---------------------------------------------------------------------
  1 | t           |                  |          2 |        16 | CA           | SK          | {"cn": "Regina", "st": "Winnipeg St", "mcp": "S"}
  2 | t           |                  |          4 |        62 | US           | UT          | {"cn": "Salt Lake City", "st": "Poplar Grove Vlvd S", "mcp": "846"}
  3 | t           |                  |          3 |           | CX           |             | {"cn": "Flying Fish Cove", "st": "Jln Pantai"}
  4 | f           | [75]             |          3 |           | CX           |             | {"cn": "Flying Fish Cove", "st": "Jln Pantai"}
  5 | f           | [75, 74, 76]     |          1 |           | AW           |             | {"cn": "San Nicolas", "st": "Sero Colorado"}
(5 rows)
*/

-- Add a civic number and mailing code random suffix
,ADD_CIVIC_MAILING_CODE AS (
  SELECT acsm.*
        ,acsm.st_city_mcp -> 'cn' AS city
        ,CASE country_code
         WHEN 'AW' THEN -- Aruba: street civic (max 2 digits)
              format(
                 '%s %s'
                ,st_city_mcp ->> 'st'
                ,(random() * 98 + 1)::int::text
              )
         WHEN 'CA' THEN -- Canada: civic (max 5 digits) street
              format(
                 '%s %s'
                ,(random() * 99998 + 1)::int::text
                ,st_city_mcp ->> 'st'
              )
         WHEN 'CX' THEN -- Christmas Island: civic (max 2 digits) street
              format(
                 '%s %s'
                ,(random() * 98 + 1)::int::text
                ,st_city_mcp ->> 'st'
              )
         WHEN 'US' THEN -- United States: civic (max 5 digits) street
              format(
                 '%s %s'
                ,(random() * 99998 + 1)::int::text
                ,st_city_mcp ->> 'st'
              )
          END address
        ,CASE country_code
         WHEN 'AW' THEN -- Aruba: no mailing code
              NULL
         WHEN 'CA' THEN -- Canada: <MCP><dig><let><sp><dig><let><dig>
              format(
                 '%s%s%s %s%s%s'
                ,st_city_mcp ->> 'mcp'
                ,chr(ascii('0') + (random() *  9)::int)
                ,chr(ascii('A') + (random() * 25)::int)
                ,chr(ascii('0') + (random() *  9)::int)
                ,chr(ascii('A') + (random() * 25)::int)
                ,chr(ascii('0') + (random() *  9)::int)
              )
         WHEN 'CX' THEN -- Christmas Island: 6798
              '6798'
         WHEN 'US' THEN -- United States: <MCP><dig><dig>(-<dig><dig><dig><dig>)?
              format(
                 '%s%s%s%s' -- MCP, dig, dig, plus four or empty
                ,st_city_mcp ->> 'mcp'
                ,chr(ascii('0') + (random() * 9)::int)
                ,chr(ascii('0') + (random() * 9)::int)
                ,CASE
                 WHEN random() < 0.8
                 THEN '' -- no plus 4
                 ELSE format(
                         '-%s%s%s%s'
                        ,chr(ascii('0') + (random() * 9)::int)
                        ,chr(ascii('0') + (random() * 9)::int)
                        ,chr(ascii('0') + (random() * 9)::int)
                        ,chr(ascii('0') + (random() * 9)::int)
                      )
                  END
              )
          END mailing_code
    FROM ADD_CITY_STREET_MCP acsm
   ORDER BY 1
)
-- SELECT * FROM ADD_CIVIC_MAILING_CODE;
/*
 ix | is_personal | address_type_ids | country_id | region_id | country_code | region_code |                      st_city_mcp                       |     city      |     address     | mailing_code
----+-------------+------------------+------------+-----------+--------------+-------------+--------------------------------------------------------+---------------+-----------------+--------------
  1 | t           |                  |          1 |           | AW           |             | {"cn": "Santa Cruz", "st": "San Fuego"}                | "Santa Cruz"  | San Fuego 97    |
  2 | t           |                  |          2 |        10 | CA           | NT          | {"cn": "Hay River", "st": "Poplar Rd", "mcp": "X"}     | "Hay River"   | 74886 Poplar Rd | X6Z 4Q5
  3 | t           |                  |          3 |           | CX           |             | {"cn": "Drumsite", "st": "Lam Lok Loh"}                | "Drumsite"    | 52 Lam Lok Loh  | 6798
  4 | t           |                  |          2 |        12 | CA           | NU          | {"cn": "Iqaluit", "st": "Mivvik St", "mcp": "X"}       | "Iqaluit"     | 8486 Mivvik St  | X1L 6Q4
  5 | f           | [75, 74]         |          4 |        27 | US           | FL          | {"cn": "Tallahassee", "st": "Monroe St", "mcp": "335"} | "Tallahassee" | 27415 Monroe St | 33552
(5 rows)
*/

-- Generate complete addresses
,GEN_ADDRESS AS (
  SELECT t.address_type_id
        ,aamc.country_id
        ,aamc.region_id
        ,aamc.city
        ,aamc.address
        ,CASE WHEN  t.address_type_id IS NOT NULL  THEN 'Door 5' END                      AS address_2
        ,CASE WHEN (t.address_type_id IS NOT NULL) AND (random() < 0.5) THEN 'Stop 6' END AS address_3
        ,aamc.mailing_code
    FROM ADD_ADDRESS_MAILING_CODE aamc
        ,jsonb_array_elements(code.IIF(jsonb_array_length(aamc.address_type_ids) as t(address_type_id)
)
SELECT * FROM GEN_ADDRESS;
/*
 address_type_id | country_id | region_id | city |        address        | address_2 | address_3 | mailing_code 
-----------------+------------+-----------+------+-----------------------+-----------+-----------+--------------
                 |          1 |           |      | Sero Colorado 9       |           |           | 
              76 |          2 |         8 |      | 97107 King St         | Door 5    |           | E6A 6A8
                 |          3 |           |      | 83 San Chye Loh       |           |           | 6798
                 |          3 |           |      | 87 Jln Pantai         |           |           | 6798
              76 |          4 |        59 |      | 82669 Ladyslipper Cir | Door 5    | Stop 6    | 57376-0163
(5 rows)
*/

-------------------

,INS_ADDRESS AS (
  -- Insert addresses using generated data
  INSERT
    INTO tables.address(
            address_type_relid
           ,country_relid
           ,region_relid
           ,city
           ,address
           ,address_2
           ,address_3
           ,mailing_code
         )
  SELECT address_type_relid
        ,country_relid
        ,region_relid
        ,city
        ,address
        ,address_2
        ,address_3
        ,mailing_code
    FROM GEN_ADDRESS
  RETURNING relid, address_type_relid
)
-- SELECT * FROM INS_ADDRESS;
/*
 relid | address_type_relid 
-------+--------------------
    89 |                 75
    90 |                   
    91 |                   
    92 |                 75
    93 |                 75
(5 rows)
*/

,ADD_INS_ADDRESS_IX AS (
   SELECT *
         ,ROW_NUMBER() OVER() AS ix
     FROM INS_ADDRESS
)
-- SELECT * FROM ADD_INS_ADDRESS_IX;
/*
 relid | address_type_relid | ix 
-------+--------------------+----
    94 |                    |  1
    95 |                 74 |  2
    96 |                 76 |  3
    97 |                    |  4
    98 |                 76 |  5
(5 rows)
*/

-- hard-coded table of customer person first names
,CUSTOMER_PERSON_FIRST_NAME_TABLE AS (
   SELECT *
         ,ROW_NUMBER() OVER() AS ix
     FROM (VALUES
             ('Anna')
            ,('Alfred')
            ,('Britney')
            ,('Bob')
            ,('Christie')
            ,('Caleb')
            ,('Denise')
            ,('Denny')
            ,('Elen')
            ,('Edward')
            ,('Fatima')
            ,('Fred')
            ,('Gale')
            ,('Glen')
            ,('Haley')
            ,('Howard')
            ,('Isabel')
            ,('Indiana')
            ,('Jenny')
            ,('James')
            ,('Kristen')
            ,('Karl')
            ,('Lisa')
            ,('Leonard')
            ,('Mona')
            ,('Michael')
            ,('Nancy')
            ,('Norman')
            ,('Oprah')
            ,('Olivia')
            ,('Patsy')
            ,('Patrick')
            ,('Queenie')
            ,('Quentin')
            ,('Roberta')
            ,('Ramsey')
            ,('Selena')
            ,('Silas')
            ,('Tina')
            ,('Tim')
            ,('Ursula')
            ,('Umar')
            ,('Victoria')
            ,('Victor')
            ,('Wendy')
            ,('William')
            ,('Xena')
            ,('Xavier')
            ,('Yolanda')
            ,('Yakov')
            ,('Zoey')
            ,('Zachary')
          ) AS s(first_name)
)
-- SELECT * FROM CUSTOMER_PERSON_FIRST_NAME_TABLE;
/* first_name | ix 
------------+----
 Anna       |  1
 Alfred     |  2
 Britney    |  3
 Bob        |  4
 ... Yolanda    | 49
 Yakov      | 50
 Zoey       | 51
 Zachary    | 52
(52 rows)
*/

-- hard-coded table of customer person last names
,CUSTOMER_PERSON_LAST_NAME_TABLE AS (
   SELECT *
         ,ROW_NUMBER() OVER() AS ix
     FROM (VALUES
             ('Adair')
            ,('Adams')
            ,('Adley')
            ,('Anderson')
            ,('Ashley')
            ,('Bardot')
            ,('Beckett')
            ,('Carter')
            ,('Cassidy')
            ,('Collymore')
            ,('Crassus')
            ,('Cromwell')
            ,('Curran')
            ,('Daughtler')
            ,('Dawson')
            ,('Ellis')
            ,('Elsher')
            ,('Finnegan')
            ,('Ford')
            ,('Gasper')
            ,('Gatlin')
            ,('Gonzales')
            ,('Gray')
            ,('Hansley')
            ,('Hayes')
            ,('Hendrix')
            ,('Hope')
            ,('Huxley')
            ,('Jenkins')
            ,('Keller')
            ,('Langley')
            ,('Ledger')
            ,('Levine')
            ,('Lennon')
            ,('Lopez')
            ,('Madison')
            ,('Marley')
            ,('McKenna')
            ,('Monroe')
            ,('Pierce')
            ,('Poverly')
            ,('Raven')
            ,('Solace')
            ,('St. James')
            ,('Stoll')
            ,('Thatcher')
            ,('Verlice')
            ,('West')
            ,('Wilson')
            ,('Zimmerman')
          ) AS s(last_name)
)
-- SELECT * FROM CUSTOMER_PERSON_LAST_NAME_TABLE;
/*
 last_name | ix 
-----------+----
 Adair     |  1
 Adams     |  2
 Adley     |  3
 Anderson  |  4
 ...
 Verlice   | 47
 West      | 48
 Wilson    | 49
 Zimmerman | 50
(50 rows)
*/

-- Add first name and last name if there is no business type
,GEN_CUSTOMER_PERSON_NAME_INDEXES AS (
  SELECT (random() * (SELECT COUNT(*) - 1 FROM CUSTOMER_PERSON_FIRST_NAME_TABLE) + 1)::INT AS fn_ix
        ,(random() * (SELECT COUNT(*) - 1 FROM CUSTOMER_PERSON_FIRST_NAME_TABLE) + 1)::INT AS mn_ix
        ,(random() * (SELECT COUNT(*) - 1 FROM CUSTOMER_PERSON_LAST_NAME_TABLE ) + 1)::INT AS ln_ix
        ,row_number AS ix
    FROM GEN_ROWS
)
-- SELECT * FROM GEN_CUSTOMER_PERSON_NAME_INDEXES;
/*
 fn_ix | mn_ix | ln_ix | ix 
-------+-------+-------+----
    14 |    47 |    11 |  1
    31 |    19 |    22 |  2
     7 |    38 |    27 |  3
    30 |    44 |    26 |  4
    38 |    20 |    37 |  5
(5 rows)
*/

-- Insert person customers using generated data and relids of inserted addresses
,INS_CUSTOMER_PERSON AS (
  INSERT
    INTO tables.customer_person(
            address_relid
           ,first_name
           ,middle_name
           ,last_name
         )
  SELECT aiai.relid
        ,cpfnt.first_name
        ,code.IIF(random() < 0.8, cpmnt.first_name, '')
        ,cplnt.last_name
    FROM ADD_INS_ADDRESS_IX aiai
    JOIN GEN_CUSTOMER_PERSON_NAME_INDEXES gcpni
      ON gcpni.ix = aiai.ix
    JOIN CUSTOMER_PERSON_FIRST_NAME_TABLE cpfnt
      ON cpfnt.ix = gcpni.fn_ix
    JOIN CUSTOMER_PERSON_FIRST_NAME_TABLE cpmnt
      ON cpmnt.ix = gcpni.mn_ix
    JOIN CUSTOMER_PERSON_LAST_NAME_TABLE  cplnt
      ON cplnt.ix = gcpni.ln_ix
   WHERE aiai.address_type_relid IS NULL
  RETURNING relid
)
-- SELECT * FROM INS_CUSTOMER_PERSON;
/*
 relid 
-------
   104
   105
   106
(3 rows)
*/

,CUSTOMER_BUSINESS_NAME_TABLE AS (
   SELECT *
         ,ROW_NUMBER() OVER() AS ix
     FROM (VALUES
             ('9 Yards Media')
            ,('Aceable, Inc.')
            ,('Aims Community College')
            ,('Bent Out of Shape Jewelry')
            ,('Compass Mortgage')
            ,('Everything But Anchovies')
            ,('Exela Movers')
            ,('Ibotta, Inc.')
            ,('Intrepid Travel')
            ,('Kaboom Fireworks')
            ,('Light As a Feather')
            ,('Like You Mean It Productions')
            ,('Marathon Physical Therapy')
            ,('More Than Words')
            ,('Percepta Security')
            ,('Semicolon Bookstore')
            ,('Soft As a Grape')
            ,('To Each Their Own, LLC')
            ,('Top It Off')
            ,('Twisters Gymnastics Academy')
            ,('Wanderu')
            ,('What You Will Yoga')
            ,('When Pigs Fly')            
          ) AS s(business_name)
)
-- SELECT * FROM CUSTOMER_BUSINESS_NAME_TABLE;
/*
        business_name         | ix 
------------------------------+----
 9 Yards Media                |  1
 Aceable, Inc.                |  2
 Aims Community College       |  3
 ...
 Wanderu                      | 21
 What You Will Yoga           | 22
 When Pigs Fly                | 23
(23 rows)
*/

-- Add first name and last name if there is no business type
,GEN_CUSTOMER_BUSINESS_NAME_INDEXES AS (
  SELECT (random() * (SELECT COUNT(*) - 1 FROM CUSTOMER_BUSINESS_NAME_TABLE    ) + 1)::INT AS bn_ix
        ,row_number AS ix
    FROM GEN_ROWS
)
-- SELECT * FROM GEN_CUSTOMER_BUSINESS_NAME_INDEXES;
/*
 bn_ix | ix 
-------+----
    20 |  1
    19 |  2
     7 |  3
     6 |  4
    14 |  5
(5 rows)
*/

-- Insert business customers using generated data and relids of inserted addresses
,INS_CUSTOMER_BUSINESS AS (
  INSERT
    INTO tables.customer_business(
            name
         )
  SELECT cbnt.business_name
    FROM ADD_INS_ADDRESS_IX aiai
    JOIN GEN_CUSTOMER_BUSINESS_NAME_INDEXES gcbni
      ON gcbni.ix = aiai.ix
    JOIN CUSTOMER_BUSINESS_NAME_TABLE cbnt
      ON cbnt.ix = gcbni.bn_ix
   WHERE aiai.address_type_relid IS NOT NULL
  RETURNING relid
)
-- SELECT * FROM INS_CUSTOMER_BUSINESS;
/*
 relid 
-------
   124
   125
   126
(3 rows)
*/

,ADD_CUSTOMER_BUSINESS_IX AS (
   SELECT *
         ,ROW_NUMBER() OVER() AS ix
     FROM INS_CUSTOMER_BUSINESS
)

-- Insert business customer address join entry
-- To line up the inserted relids with ADD_INS_ADDRESS_IX indexes:
-- Add
,INS_CUSTOMER_BUSINESS_ADDRESS_JOIN AS (
  INSERT
    INTO tables.customer_business_address_jt(
            business_relid
           ,address_relid
         )
  SELECT icb.relid
    FROM ADD_INS_ADDRESS_IX aiai
    JOIN INS_CUSTOMER_BUSINESS icb
      ON icb.
)

truncate table tables.address cascade;
