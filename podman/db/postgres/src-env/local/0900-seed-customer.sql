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

-- truncate table tables.address cascade;

-- Generate NUM_ROWS rows using generate_series
-- Generate 0 rows if there are already addresses in the system
,GEN_ROWS AS (
   SELECT generate_series(1, NUM_ROWS)
     FROM PARAMS
    WHERE (SELECT COUNT(*) FROM tables.address) = 0
)
-- SELECT * FROM GEN_ROWS;
/*
 generate_series
-----------------
               1
               2
               3
               4
               5
(5 rows)
*/

-- Choose 60% personal addresses and 40% business addresses
,IS_PERSONAL AS (
   SELECT random() <= 0.60 AS is_personal
     FROM GEN_ROWS
)
-- SELECT * FROM IS_PERSONAL;
/*
 is_personal
-------------
 t
 t
 f
 t
 t
(5 rows)
*/

-- Add a row number partitioned by is_personal
-- We need to have separate 1 .. n row numbers for personal and bussiness addresses
,ADD_PARTITIONED_CUSTOMER_NUM AS (
   SELECT is_personal
         ,row_number() over(partition by is_personal) cn
     FROM IS_PERSONAL
    ORDER BY is_personal, cn
)
-- SELECT * FROM ADD_PARTITIONED_CUSTOMER_NUM;
/*
 is_personal | cn
-------------+----
 f           |  1
 f           |  2
 t           |  1
 t           |  2
 t           |  3
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
           ) address_type_relids
      FROM ADD_PARTITIONED_CUSTOMER_NUM
     ORDER BY is_personal, cn
)
-- SELECT * FROM ADD_ADDRESS_TYPE_IDS;
/*
 is_personal | cn | address_type_relids
-------------+----+---------------------
 f           |  1 | [75, 76, 74]
 f           |  2 | [76, 74]
 f           |  3 | [76]
 t           |  1 |
 t           |  2 |
(5 rows)
*/

-- Expand address type ids into seperate rows
-- ,jsonb_array_elements(COALESCE(acmc.address_type_ids, '[null]'::jsonb)) as t(address_type_id)
,EXPAND_ADDRESS_TYPE_IDS AS (
    SELECT aati.is_personal
          ,aati.cn
          ,row_number() over(partition by is_personal order by cn, address_type_relid) an
          ,(t.address_type_relid #>> '{}')::BIGINT address_type_relid
      FROM ADD_ADDRESS_TYPE_IDS aati
          ,jsonb_array_elements(COALESCE(aati.address_type_relids, '[null]'::jsonb)) as t(address_type_relid)
     ORDER BY is_personal, an
)
-- SELECT * FROM EXPAND_ADDRESS_TYPE_IDS;
/*
 is_personal | cn | an | address_type_relid
-------------+----+----+--------------------
 f           |  1 |  1 |                 75
 f           |  1 |  2 |                 76
 f           |  2 |  3 |                 75
 f           |  2 |  4 |                 76
 t           |  1 |  1 |
 t           |  2 |  2 |
 t           |  3 |  3 |
(7 rows)
*/

-- Add a random country id from all available
,ADD_COUNTRY_ID AS (
    SELECT *
          ,code.JSONB_ARRAY_RANDOM((SELECT jsonb_agg(relid) FROM tables.COUNTRY))::BIGINT country_relid
      FROM EXPAND_ADDRESS_TYPE_IDS
     ORDER BY is_personal, an
)
-- SELECT * FROM ADD_COUNTRY_ID;
/*
 is_personal | cn | an | address_type_relid | country_relid
-------------+----+----+--------------------+---------------
 f           |  1 |  1 |                 75 |             1
 f           |  1 |  2 |                 76 |             2
 f           |  2 |  3 |                 75 |             3
 f           |  2 |  4 |                 76 |             4
 f           |  3 |  5 |                 75 |             3
 f           |  3 |  6 |                 76 |             3
 t           |  1 |  1 |                    |             4
 t           |  2 |  2 |                    |             2
(8 rows)
*/

-- Generate a random region id of all regions for the chosen country (null if country has no regions)
,ADD_REGION_ID AS (
    SELECT *
          ,code.JSONB_ARRAY_RANDOM((SELECT jsonb_agg(relid) FROM tables.REGION r WHERE r.country_relid = aci.country_relid))::BIGINT region_relid
      FROM ADD_COUNTRY_ID aci
     ORDER BY is_personal, an
)
-- SELECT * FROM ADD_REGION_ID;
/*
 is_personal | cn | an | address_type_relid | country_relid | region_relid
-------------+----+----+--------------------+---------------+--------------
 f           |  1 |  1 |                 74 |             2 |            6
 f           |  1 |  2 |                 75 |             2 |            9
 f           |  2 |  3 |                 74 |             1 |
 f           |  2 |  4 |                 75 |             1 |
 f           |  2 |  5 |                 76 |             1 |
 f           |  3 |  6 |                 74 |             4 |           55
 f           |  3 |  7 |                 75 |             1 |
 f           |  3 |  8 |                 76 |             3 |
 f           |  4 |  9 |                 74 |             3 |
 f           |  4 | 10 |                 75 |             3 |
 t           |  1 |  1 |                    |             4 |           37
(11 rows)
*/

-- Add country and region codes
,ADD_COUNTRY_REGION_CODES AS (
    SELECT ari.*
          ,c.code_2 AS country_code
          ,r.code   AS  region_code
      FROM ADD_REGION_ID ari
      JOIN tables.country c
        ON c.relid = ari.country_relid
      LEFT
      JOIN tables.region r
        ON r.relid = ari.region_relid
     ORDER BY is_personal, an
)
-- SELECT * FROM ADD_COUNTRY_REGION_CODES;
/*
 is_personal | cn | an | address_type_relid | country_relid | region_relid | country_code | region_code
-------------+----+----+--------------------+---------------+--------------+--------------+-------------
 f           |  1 |  1 |                 74 |             4 |           67 | US           | WI
 f           |  1 |  2 |                 76 |             3 |              | CX           |
 f           |  2 |  3 |                 74 |             2 |           14 | CA           | PE
 f           |  2 |  4 |                 75 |             1 |              | AW           |
 f           |  2 |  5 |                 76 |             2 |            7 | CA           | MB
 t           |  1 |  1 |                    |             1 |              | AW           |
 t           |  2 |  2 |                    |             2 |            7 | CA           | MB
 t           |  3 |  3 |                    |             3 |              | CX           |
(8 rows)
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
   ORDER BY is_personal, an
)
-- SELECT * FROM ADD_CITY_STREET_MCP;
/*
 is_personal | cn | an | address_type_relid | country_relid | region_relid | country_code | region_code |                         st_city_mcp
-------------+----+----+--------------------+---------------+--------------+--------------+-------------+-------------------------------------------------------------
 f           |  1 |  1 |                 76 |             2 |           11 | CA           | NS          | {"cn": "Sydney", "st": "Dorchester St", "mcp": "B"}
 f           |  2 |  2 |                 74 |             4 |           71 | US           | MP          | {"cn": "Marpi", "st": "Ayuyu Dr", "mcp": "969"}
 f           |  2 |  3 |                 75 |             2 |           13 | CA           | ON          | {"cn": "Ottawa", "st": "Wellington St", "mcp": "L"}
 f           |  2 |  4 |                 76 |             2 |            8 | CA           | NB          | {"cn": "Moncton", "st": "King St", "mcp": "E"}
 t           |  1 |  1 |                    |             2 |           12 | CA           | NU          | {"cn": "Iqaluit", "st": "Mivvik St", "mcp": "X"}
 t           |  2 |  2 |                    |             2 |           15 | CA           | QC          | {"cn": "Montreal", "st": "Sainte-Catherine St", "mcp": "H"}
 t           |  3 |  3 |                    |             2 |           16 | CA           | SK          | {"cn": "Saskatoon", "st": "Broadway Ave", "mcp": "S"}
(7 rows)
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
   ORDER BY is_personal, an
)
-- SELECT * FROM ADD_CIVIC_MAILING_CODE;
/*
 is_personal | cn | an | address_type_relid | country_relid | region_relid | country_code | region_code |                        st_city_mcp                        |        city        |         address         | mailing_code
-------------+----+----+--------------------+---------------+--------------+--------------+-------------+-----------------------------------------------------------+--------------------+-------------------------+--------------
 f           |  1 |  1 |                 74 |             3 |              | CX           |             | {"cn": "Flying Fish Cove", "st": "Jln Pantai"}            | "Flying Fish Cove" | 20 Jln Pantai           | 6798
 f           |  1 |  2 |                 75 |             3 |              | CX           |             | {"cn": "Poon Saan", "st": "San Chye Loh"}                 | "Poon Saan"        | 92 San Chye Loh         | 6798
 f           |  1 |  3 |                 76 |             4 |           19 | US           | AK          | {"cn": "Juneau", "st": "South Franklin St", "mcp": "996"} | "Juneau"           | 12613 South Franklin St | 99642-6304
 f           |  2 |  4 |                 74 |             3 |              | CX           |             | {"cn": "Silver City", "st": "Sea View Dr"}                | "Silver City"      | 73 Sea View Dr          | 6798
 f           |  2 |  5 |                 76 |             3 |              | CX           |             | {"cn": "Flying Fish Cove", "st": "Jln Pantai"}            | "Flying Fish Cove" | 40 Jln Pantai           | 6798
 t           |  1 |  1 |                    |             3 |              | CX           |             | {"cn": "Poon Saan", "st": "San Chye Loh"}                 | "Poon Saan"        | 57 San Chye Loh         | 6798
 t           |  2 |  2 |                    |             1 |              | AW           |             | {"cn": "San Nicolas", "st": "Sero Colorado"}              | "San Nicolas"      | Sero Colorado 3         |
 t           |  3 |  3 |                    |             2 |            5 | CA           | AB          | {"cn": "Calgary", "st": "17th Ave SW", "mcp": "T"}        | "Calgary"          | 97272 17th Ave SW       | T4P 3D1
(8 rows)
*/

-- Generate complete addresses
,GEN_ADDRESS AS (
  SELECT is_personal
        ,cn
        ,an
        ,address_type_relid
        ,country_relid
        ,region_relid
        ,city
        ,address
        ,code.IIF(is_personal, NULL::TEXT, 'Door 5') AS address_2
        ,code.IIF(is_personal, NULL::TEXT, 'Stop 6') AS address_3
        ,mailing_code
    FROM ADD_CIVIC_MAILING_CODE
   ORDER BY is_personal, an
)
-- SELECT * FROM GEN_ADDRESS;
/*
 is_personal | cn | an | address_type_relid | country_relid | region_relid |        city        |       address       | address_2 | address_3 | mailing_code
-------------+----+----+--------------------+---------------+--------------+--------------------+---------------------+-----------+-----------+--------------
 f           |  1 |  1 |                 74 |             2 |            9 | "St John's"        | 79849 George St     | Door 5    | Stop 6    | A4Q 5L2
 f           |  1 |  2 |                 76 |             3 |              | "Flying Fish Cove" | 9 Jln Pantai        | Door 5    | Stop 6    | 6798
 f           |  2 |  3 |                 74 |             1 |              | "San Nicolas"      | Sero Colorado 81    | Door 5    | Stop 6    |
 f           |  2 |  4 |                 75 |             3 |              | "Flying Fish Cove" | 44 Jln Pantai       | Door 5    | Stop 6    | 6798
 f           |  3 |  5 |                 74 |             2 |           11 | "Sydney"           | 22712 Dorchester St | Door 5    | Stop 6    | B2O 6B8
 f           |  3 |  6 |                 76 |             4 |           71 | "Saipan"           | 59573 Tapochao Rd   | Door 5    | Stop 6    | 96930
 f           |  4 |  7 |                 74 |             3 |              | "Silver City"      | 39 Sea View Dr      | Door 5    | Stop 6    | 6798
 f           |  4 |  8 |                 75 |             3 |              | "Silver City"      | 19 Sea View Dr      | Door 5    | Stop 6    | 6798
 t           |  1 |  1 |                    |             3 |              | "Poon Saan"        | 86 San Chye Loh     |           |           | 6798
(9 rows)
*/

-- Insert addresses, returning the generated relid and address_type_relid
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
   ORDER BY is_personal, an
  RETURNING relid, address_type_relid
)
-- SELECT * FROM INS_ADDRESS;
/*
 relid | address_type_relid 
-------+--------------------
   187 |                 74
   188 |                 76
   189 |
   190 |
   191 |
   192 |
(6 rows)
*/

-- The generated address relids are sequential
-- Add a sequential an column partitioned on is_personal
,ADD_INS_ADDRESS_AN AS (
   SELECT address_type_relid IS NULL AS is_personal
         ,row_number() over(partition by address_type_relid IS NULL order by relid) an
         ,*
     FROM INS_ADDRESS
    ORDER BY is_personal, an
)
-- SELECT * FROM ADD_INS_ADDRESS_AN;
/*
 is_personal | an | relid | address_type_relid
-------------+----+-------+--------------------
 f           |  1 |   227 |                 74
 f           |  2 |   228 |                 76
 f           |  3 |   229 |                 75
 f           |  4 |   230 |                 74
 f           |  5 |   231 |                 76
 t           |  1 |   232 |
 t           |  2 |   233 |
(7 rows)
*/

-- Join the GEN_ADDRESS an column to the ADD_INS_ADDRESS_AN an column
,JOIN_GEN_ADDRESS_INS_ADDRESS AS (
   SELECT ga.*
         ,aiaa.relid as address_relid
     FROM GEN_ADDRESS ga
     JOIN ADD_INS_ADDRESS_AN aiaa
       ON ga.is_personal = aiaa.is_personal
      AND ga.an = aiaa.an
    ORDER BY is_personal, an
)
-- SELECT * FROM JOIN_GEN_ADDRESS_INS_ADDRESS;
/*
 is_personal | cn | an | address_type_relid | country_relid | region_relid |        city        |      address      | address_2 | address_3 | mailing_code | address_relid
-------------+----+----+--------------------+---------------+--------------+--------------------+-------------------+-----------+-----------+--------------+---------------
 f           |  1 |  1 |                 74 |             3 |              | "Flying Fish Cove" | 24 Jln Pantai     | Door 5    | Stop 6    | 6798         |           247
 f           |  1 |  2 |                 75 |             3 |              | "Flying Fish Cove" | 57 Jln Pantai     | Door 5    | Stop 6    | 6798         |           248
 f           |  1 |  3 |                 76 |             1 |              | "Oranjestad"       | Spinozastraat 61  | Door 5    | Stop 6    |              |           249
 f           |  2 |  4 |                 75 |             1 |              | "San Nicolas"      | Sero Colorado 33  | Door 5    | Stop 6    |              |           250
 f           |  2 |  5 |                 76 |             4 |           51 | "Marpi"            | 83141 Ayuyu Dr    | Door 5    | Stop 6    | 27463        |           251
 t           |  1 |  1 |                    |             1 |              | "Oranjestad"       | Spinozastraat 26  |           |           |              |           252
 t           |  2 |  2 |                    |             2 |           14 | "Charlottetown"    | 24564 Richmond St |           |           | C4I 6V4      |           253
 t           |  3 |  3 |                    |             3 |              | "Poon Saan"        | 6 San Chye Loh    |           |           | 6798         |           254
(8 rows)
*/

-- Hard-coded table of customer person first names
,CUSTOMER_PERSON_FIRST_NAME_TABLE AS (
   SELECT ROW_NUMBER() OVER() AS ix
         ,*
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
/*
 ix | first_name
----+------------
  1 | Anna
  2 | Alfred
  3 | Britney
 ...
 50 | Yakov
 51 | Zoey
 52 | Zachary
(52 rows)
*/

-- Hard-coded table of customer person last names
,CUSTOMER_PERSON_LAST_NAME_TABLE AS (
   SELECT ROW_NUMBER() OVER() AS ix
         ,*
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
 ix | last_name
----+-----------
  1 | Adair
  2 | Adams
  3 | Adley
 ...
 49 | Wilson
 50 | Zimmerman
(50 rows)
*/

-- Hard-coded table of business names
,CUSTOMER_BUSINESS_NAME_TABLE AS (
   SELECT ROW_NUMBER() OVER() AS ix
         ,*
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
 ix |        business_name
----+------------------------------
  1 | 9 Yards Media
  2 | Aceable, Inc.
  3 | Aims Community College
 ...
 21 | Wanderu
 22 | What You Will Yoga
 23 | When Pigs Fly
(23 rows)
*/

-- Add first name, middle name (40% of the time), and last name if it is a personal address
-- Add business name if it is a business address
,ADD_CUSTOMER_PERSON_BUSINESS_NAME_INDEXES AS (
  SELECT *
        ,code.IIF(    is_personal                       , (random() * (SELECT COUNT(*) - 1 FROM CUSTOMER_PERSON_FIRST_NAME_TABLE) + 1)::INT, NULL) as fn_ix
        ,code.IIF(    is_personal AND (random() <= 0.40), (random() * (SELECT COUNT(*) - 1 FROM CUSTOMER_PERSON_FIRST_NAME_TABLE) + 1)::INT, NULL) as mn_ix
        ,code.IIF(    is_personal                       , (random() * (SELECT COUNT(*) - 1 FROM CUSTOMER_PERSON_LAST_NAME_TABLE ) + 1)::INT, NULL) as ln_ix
        ,code.IIF(NOT is_personal,                        (random() * (SELECT COUNT(*) - 1 FROM CUSTOMER_BUSINESS_NAME_TABLE    ) + 1)::INT, NULL) as bn_ix
    FROM JOIN_GEN_ADDRESS_INS_ADDRESS
   ORDER BY is_personal, an
)
-- SELECT * FROM ADD_CUSTOMER_PERSON_BUSINESS_NAME_INDEXES;
/*
 is_personal | cn | an | address_type_relid | country_relid | region_relid |        city        |         address          | address_2 | address_3 | mailing_code | address_relid | fn_ix | mn_ix | ln_ix | bn_ix
-------------+----+----+--------------------+---------------+--------------+--------------------+--------------------------+-----------+-----------+--------------+---------------+-------+-------+-------+-------
 f           |  1 |  1 |                 74 |             1 |              | "Paradera"         | Bloemond 41              | Door 5    | Stop 6    |              |           263 |       |       |       |    20
 f           |  1 |  2 |                 75 |             3 |              | "Flying Fish Cove" | 41 Jln Pantai            | Door 5    | Stop 6    | 6798         |           264 |       |       |       |    14
 f           |  1 |  3 |                 76 |             4 |           55 | "Salem"            | 17327 Chestnut St        | Door 5    | Stop 6    | 97123        |           265 |       |       |       |    20
 f           |  2 |  4 |                 74 |             2 |            6 | "Vancouver"        | 51319 Robson St          | Door 5    | Stop 6    | V1M 2B1      |           266 |       |       |       |    14
 f           |  2 |  5 |                 75 |             4 |           20 | "Phoenix"          | 98775 Van Buren St       | Door 5    | Stop 6    | 85654        |           267 |       |       |       |     2
 f           |  2 |  6 |                 76 |             3 |              | "Flying Fish Cove" | 76 Jln Pantai            | Door 5    | Stop 6    | 6798         |           268 |       |       |       |     2
 f           |  3 |  7 |                 74 |             2 |           15 | "Quebec City"      | 71569 Petit-Champlain St | Door 5    | Stop 6    | H5I 2R9      |           269 |       |       |       |    20
 f           |  3 |  8 |                 75 |             3 |              | "Flying Fish Cove" | 98 Jln Pantai            | Door 5    | Stop 6    | 6798         |           270 |       |       |       |    20
 f           |  3 |  9 |                 76 |             2 |           14 | "Summerside"       | 16662 Water St           | Door 5    | Stop 6    | C3Q 0P7      |           271 |       |       |       |     8
 t           |  1 |  1 |                    |             2 |           11 | "Sydney"           | 70879 Dorchester St      |           |           | B8K 6P1      |           272 |    31 |       |     7 |
 t           |  2 |  2 |                    |             2 |           14 | "Summerside"       | 74705 Water St           |           |           | C8C 9D1      |           273 |    43 |    51 |    14 |
(11 rows)
*/

-- Add person and business names
,ADD_CUSTOMER_PERSON_BUSINESS_NAMES AS (
   SELECT acpbni.*
         ,cpfnt.first_name
         ,cpmnt.first_name AS middle_name
         ,cplnt.last_name
         ,cbnt.business_name
     FROM ADD_CUSTOMER_PERSON_BUSINESS_NAME_INDEXES acpbni
     LEFT
     JOIN CUSTOMER_PERSON_FIRST_NAME_TABLE cpfnt
       ON cpfnt.ix = acpbni.fn_ix
     LEFT
     JOIN CUSTOMER_PERSON_FIRST_NAME_TABLE cpmnt
       ON cpmnt.ix = acpbni.mn_ix
     LEFT
     JOIN CUSTOMER_PERSON_LAST_NAME_TABLE cplnt
       ON cplnt.ix = acpbni.ln_ix
     LEFT
     JOIN CUSTOMER_BUSINESS_NAME_TABLE cbnt
       ON cbnt.ix = acpbni.bn_ix
)
-- SELECT * FROM ADD_CUSTOMER_PERSON_BUSINESS_NAMES;
/*
 is_personal | cn | an | address_type_relid | country_relid | region_relid |        city        |      address       | address_2 | address_3 | mailing_code | address_relid | fn_ix | mn_ix | ln_ix | bn_ix | first_name | middle_name | last_name |       business_name
-------------+----+----+--------------------+---------------+--------------+--------------------+--------------------+-----------+-----------+--------------+---------------+-------+-------+-------+-------+------------+-------------+-----------+---------------------------
 f           |  1 |  1 |                 74 |             4 |           46 | "Carson City"      | 92558 E William St | Door 5    | Stop 6    | 89421        |           285 |       |       |       |    17 |            |             |           | Soft As a Grape
 f           |  1 |  2 |                 76 |             3 |              | "Poon Saan"        | 52 San Chye Loh    | Door 5    | Stop 6    | 6798         |           286 |       |       |       |     4 |            |             |           | Bent Out of Shape Jewelry
 t           |  1 |  1 |                    |             2 |            5 | "Calgary"          | 58866 17th Ave SW  |           |           | T5V 2G8      |           287 |    26 |    29 |    19 |       | Michael    | Oprah       | Ford      |
 t           |  2 |  2 |                    |             3 |              | "Flying Fish Cove" | 62 Jln Pantai      |           |           | 6798         |           288 |    52 |    14 |    11 |       | Zachary    | Glen        | Crassus   |
 t           |  3 |  3 |                    |             3 |              | "Poon Saan"        | 53 San Chye Loh    |           |           | 6798         |           289 |    20 |       |    40 |       | James      |             | Pierce    |
 t           |  4 |  4 |                    |             3 |              | "Drumsite"         | 28 Lam Lok Loh     |           |           | 6798         |           290 |    22 |       |    25 |       | Karl       |             | Hayes     |
(6 rows)
*/

-- Insert person customers using generated data and relids of already inserted addresses
,INS_CUSTOMER_PERSON AS (
  INSERT
    INTO tables.customer_person(
            address_relid
           ,first_name
           ,middle_name
           ,last_name
         )
  SELECT address_relid
        ,first_name
        ,middle_name
        ,last_name
    FROM ADD_CUSTOMER_PERSON_BUSINESS_NAMES
   WHERE is_personal
   ORDER BY an
  RETURNING relid
)
-- SELECT * FROM INS_CUSTOMER_PERSON;
/*
 relid 
-------
   183
   184
   185
   186
(4 rows)
*/

-- Insert business customers using generated data and relids of inserted addresses
,INS_CUSTOMER_BUSINESS AS (
  INSERT
    INTO tables.customer_business(
            name
         )
  SELECT business_name
    FROM ADD_CUSTOMER_PERSON_BUSINESS_NAMES
   WHERE NOT is_personal
   ORDER BY an
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

-- The generated address relids are sequential
-- Add a sequential an column partitioned on is_personal
,ADD_INS_BUSINESS_ADDRESS_AN AS (
   SELECT
     FROM INS_ADDRESS ia
     JOIN INS_CUSTOMER_BUSINESS icb
    ORDER BY is_personal, an
)
-- SELECT * FROM ADD_INS_ADDRESS_AN;

-- Insert business customer address join entry
-- To line up the inserted relids with ADD_INS_ADDRESS_IX indexes:
-- Add
,INS_CUSTOMER_BUSINESS_ADDRESS_JOIN AS (
  INSERT
    INTO tables.customer_business_address_jt(
            business_relid
           ,address_relid
         )
  SELECT
    FROM ADD_CUSTOMER_PERSON_BUSINESS_NAMES acpbn
   WHERE NOT is_personal
)

truncate table tables.address cascade;
