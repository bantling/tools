-- Seed addresses

-- Parameters for seeding
WITH PARAMS AS (
  SELECT 5 AS num_rows
   WHERE (SELECT COUNT(*) FROM tables.address) = 0
)
-- SELECT * FROM PARAMS;
/*
 num_rows 
----------
        5 
(1 row)
*/

-- Multiply the one params row by the num_rows value
,GEN_ROWS AS (
 SELECT p.*
       ,ROW_NUMBER() OVER()
   FROM PARAMS p
       ,generate_series(1, num_rows) r
)
-- SELECT * FROM GEN_ROWS;
/*
 num_rows | row_number 
----------+------------
        5 |          1
        5 |          2
        5 |          3
        5 |          4
        5 |          5
(5 rows)
*/

-- Generate the list of ordered address type relids with 1-based indexes
,ADDRESS_TYPE_RELID_INDEXES AS (
 SELECT relid
       ,ROW_NUMBER() OVER(ORDER BY ord) AS ix
   FROM tables.address_type
)
-- SELECT * FROM ADDRESS_TYPE_RELID_INDEXES;
/*
 relid | ix 
-------+----
    73 |  1
    74 |  2
    75 |  3
(3 rows)
*/

-- Generate the list of ordered country relids with 1-based indexes
,COUNTRY_RELID_INDEXES AS (
 SELECT relid
       ,ROW_NUMBER() OVER(ORDER BY name) AS ix
   FROM tables.country
)
-- SELECT * FROM COUNTRY_RELID_INDEXES;
/*
 relid | ix 
-------+----
     1 |  1
     2 |  2
     3 |  3
     4 |  4
(4 rows)
*/

-- Generate the list of ordered region relids with 1-based indexes for each country
,REGION_RELID_INDEXES_BY_COUNTRY AS (
 SELECT country_relid
       ,relid
       ,ROW_NUMBER() OVER(PARTITION BY country_relid ORDER BY ord) AS ix
   FROM tables.region
)
-- SELECT * FROM REGION_RELID_INDEXES_BY_COUNTRY;
/*
 country_relid | relid | ix 
---------------+-------+----
             2 |     5 |  1
             2 |     6 |  2
             2 |     7 |  3
...
             4 |    18 |  1
             4 |    19 |  2
             4 |    20 |  3
...
(68 rows)
*/

-- Generate random address type indexes
-- NULL indexes indicate a personal address, non-null indicates a business address
,GEN_ADDRESS_TYPE_INDEXES AS (
 SELECT code.IIF(random() >= 0.5, (random() * (SELECT COUNT(*) - 1 FROM ADDRESS_TYPE_RELID_INDEXES) + 1)::INT, NULL) AS ix
       ,row_number
   FROM GEN_ROWS
)
-- SELECT * FROM GEN_ADDRESS_TYPE_INDEXES;
/*
 ix | row_number 
----+------------
    |          1
  3 |          2
    |          3
    |          4
  1 |          5
(5 rows)
*/

-- Generate random country indexes
,GEN_COUNTRY_INDEXES AS (
 SELECT (random() * (SELECT COUNT(*) - 1 FROM COUNTRY_RELID_INDEXES) + 1)::INT AS ix
       ,row_number
   FROM GEN_ROWS
)
-- SELECT * FROM GEN_COUNTRY_INDEXES;
/*
 ix | row_number 
----+------------
  3 |          1
  2 |          2
  4 |          3
  2 |          4
  3 |          5
(5 rows)
*/

-- Generate random region indexes (null for coutries with no regions)
,GEN_REGION_INDEXES AS (
 SELECT code.IIF(c.has_regions, (random() * (SELECT COUNT(*) - 1 FROM REGION_RELID_INDEXES_BY_COUNTRY WHERE country_relid = c.relid) + 1)::INT, NULL) ix
       ,gci.row_number
   FROM GEN_COUNTRY_INDEXES gci
   JOIN COUNTRY_RELID_INDEXES cri
     ON cri.ix = gci.ix
   JOIN tables.country c
     ON c.relid = cri.relid
)
-- SELECT * FROM GEN_REGION_INDEXES;
/*
 ix | row_number 
----+------------
    |          4
  7 |          3
    |          1
 14 |          5
 49 |          2
(5 rows)
*/

-- Translate  address type, country, and region indexes into relids
-- - address types are optional: only business addresses have them
-- - regions are optional: not all couintries have them
,TR_ADDRESS_TYPE_COUNTRY_REGION_INDEXES_TO_RELIDS AS (
  SELECT  atri.relid AS address_type_relid
        ,  cri.relid AS country_relid
        ,rribc.relid AS region_relid
    FROM GEN_ADDRESS_TYPE_INDEXES gati
    LEFT
    JOIN ADDRESS_TYPE_RELID_INDEXES atri
      ON atri.ix = gati.ix
    JOIN GEN_COUNTRY_INDEXES gci
      ON gci.row_number = gati.row_number
    JOIN COUNTRY_RELID_INDEXES cri
      ON cri.ix = gci.ix
    JOIN GEN_REGION_INDEXES gri
      ON gri.row_number = gati.row_number
    LEFT
    JOIN REGION_RELID_INDEXES_BY_COUNTRY rribc
      ON rribc.country_relid = cri.relid
     AND rribc.ix = gri.ix
)
-- SELECT * FROM TR_ADDRESS_TYPE_COUNTRY_REGION_INDEXES_TO_RELIDS;
/*
 address_type_relid | country_relid | region_relid 
--------------------+---------------+--------------
                 75 |             3 |             
                    |             3 |             
                    |             1 |             
                    |             4 |           58
                    |             2 |            9
(5 rows)
*/

-- Generate {st: street, cn: city, mcp: mailing code prefix (optional)} object for chosen country/region
, ADD_CITY_STREET_MCP AS (
  SELECT d.*
        ,CASE c.code_2
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
           CASE r.code
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
               ,jsonb_build_array(
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
               ,jsonb_build_array(
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
                       json_build_array('G', 'H', 'J') -> (random() * 2)::int
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
           CASE r.code
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
           WHEN 'PR' THEN -- Puerto Rico
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
            END
          END st_city_mcp
    FROM TR_ADDRESS_TYPE_COUNTRY_REGION_INDEXES_TO_RELIDS d
    JOIN tables.country c
      ON c.relid = d.country_relid
    LEFT
    JOIN tables.region r
      ON r.relid = d.region_relid
)
-- SELECT * FROM ADD_CITY_STREET_MCP;
/*
 address_type_relid | country_relid | region_relid |                      st_city_mcp                       
--------------------+---------------+--------------+--------------------------------------------------------
                 74 |             2 |           12 | {"cn": "Iqaluit", "st": "Mivvik St", "mcp": "X"}
                 75 |             4 |           27 | {"cn": "Jacksonville", "st": "Laura St", "mcp": "320"}
                    |             3 |              | {"cn": "Flying Fish Cove", "st": "Jln Pantai"}
                    |             3 |              | {"cn": "Poon Saan", "st": "San Chye Loh"}
                    |             1 |              | {"cn": "Oranjestad", "st": "Spinozastraat"}
(5 rows)
*/

, ADD_ADDRESS_MAILING_CODE AS (
  SELECT d.*
        ,CASE c.code_2
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
        ,CASE c.code_2
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
    FROM ADD_CITY_STREET_MCP d
    JOIN tables.country c
      ON c.relid = d.country_relid
    LEFT
    JOIN tables.region r
      ON r.relid = d.region_relid
)
 SELECT * FROM ADD_ADDRESS_MAILING_CODE;
/*
 address_type_relid | country_relid | region_relid |                       st_city_mcp                        |        address        | mailing_code 
--------------------+---------------+--------------+----------------------------------------------------------+-----------------------+--------------
                    |             1 |              | {"cn": "Santa Cruz", "st": "San Fuego"}                  | San Fuego 78          | 
                    |             2 |           12 | {"cn": "Rankin Inlet", "st": "TikTaq Ave", "mcp": "X"}   | 26344 TikTaq Ave      | X2H 5L3
                    |             2 |           17 | {"cn": "Dawson City", "st": "4th Ave", "mcp": "Y"}       | 30554 4th Ave         | Y1V 8X8
                    |             3 |              | {"cn": "Poon Saan", "st": "San Chye Loh"}                | 23 San Chye Loh       | 6798
                 73 |             4 |           34 | {"cn": "Wichita", "st": "S Hydraulic Ave", "mcp": "678"} | 35314 S Hydraulic Ave | 67824
(5 rows)
*/

, GEN_ADDRESS AS (
  SELECT d.type_relid AS type_relid
        ,d.country_relid
        ,d.region_relid
        ,gen_random_uuid()                                                           AS address_id
        ,gen_random_uuid()                                                           AS customer_id
        ,1                                                                           AS version
        ,current_timestamp                                                           AS created
        ,current_timestamp                                                           AS changed
        ,d.st_city_mcp ->> 'cn'                                                      AS city
        ,d.address                                                                   AS address
        ,CASE WHEN d.type_relid IS NOT NULL THEN 'Door 5' END                        AS address_2
        ,CASE WHEN (d.type_relid IS NOT NULL) AND (random() < 0.5) THEN 'Stop 6' END AS address_3
        ,d.mailing_code
    FROM ADD_ADDRESS_MAILING_CODE d
   ORDER BY d.type_relid
)
-- SELECT * FROM GEN_ADDRESS;
--  type_relid | country_relid | region_relid |              address_id              |             customer_id              | version |            created            |            changed            |    city    |     address     | address_2 | address_3 | mailing_code 
-- ------------+---------------+--------------+--------------------------------------+--------------------------------------+---------+-------------------------------+-------------------------------+------------+-----------------+-----------+-----------+--------------
--           1 |             1 |              | 90edd4e0-aa0c-42eb-b43a-9a9927d10fe0 | c4f741b3-f65b-466b-8345-c764fd8a3568 |       1 | 2024-08-07 11:56:54.501702+00 | 2024-08-07 11:56:54.501702+00 | Oranjestad | Spinozastraat 6 | Door 5    |           | 
--           1 |             2 |            4 | 911dad43-a07f-4eb9-9be4-bac1b4935352 | 92f439dd-05a8-4b15-a2a3-13d230ab98a5 |       1 | 2024-08-07 11:56:54.501702+00 | 2024-08-07 11:56:54.501702+00 | Moncton    | 24343 King St   | Door 5    | Stop 6    | E7S 7D3
--           1 |             3 |              | 529960ee-4ffc-4df0-91b0-bd605977710c | 8517b830-15c6-4d53-b23f-cc3349beb35b |       1 | 2024-08-07 11:56:54.501702+00 | 2024-08-07 11:56:54.501702+00 | Poon Saan  | 14 San Chye Loh | Door 5    | Stop 6    | 6798
--           2 |             4 |           19 | 6d4847d9-fe0f-4b23-a782-c3aefea57d57 | 0f2ac23c-307a-47ad-84f3-56976da5c9ed |       1 | 2024-08-07 11:56:54.501702+00 | 2024-08-07 11:56:54.501702+00 | Sacramento | 72916 K St      | Door 5    |           | 92368-5361
--             |             3 |              | bdb7e2c0-761a-499f-bb2d-6dfab08c697a | 4d891a78-c3b0-48e9-b952-fd02864306f4 |       1 | 2024-08-07 11:56:54.501702+00 | 2024-08-07 11:56:54.501702+00 | Poon Saan  | 18 San Chye Loh |           |           | 6798
-- (5 rows)

-- Insert addresses using generated data
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
      ,address_id
      ,version
      ,created
      ,changed
      ,city
      ,address
      ,address_2
      ,address_3
      ,mailing_code
  FROM GEN_ADDRESS;

-- Insert person customers with a reference to their addresses
-- Order the addresses by their relids, joining the nth customer to the nth address
-- The relids won't match:
-- - the business relids will be from 1 to N
-- - the addresss relids will not necessarily be consecutive, as they are intermixed with person addresses
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
SELECT t.relid
      ,gen_random_uuid()
      ,1
      ,current_timestamp
      ,current_timestamp
      ,'John'
      ,'James'
      ,'Doe'
  FROM tables.address t
 WHERE t.type_relid IS NULL
 ORDER
    BY t.relid;

-- Insert business customers, one per businness address
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
  FROM tables.address t
 WHERE t.type_relid IS NOT NULL;

-- Insert join entries from business customers to their addresses
-- Order the businesses and their addresses by their relids, joining the nth business to the nth address
-- The relids won't match:
-- - the business relids will be from 1 to N
-- - the addresss relids will not necessarily be consecutive, as they are intermixed with person addresses
-- So join the addresses to the businesses by generating row numbers
INSERT
  INTO tables.customer_business_address_jt(
           business_relid
          ,address_relid
       )
WITH BUSINESS_ADDRESS AS (
  SELECT relid
        ,row_number() OVER() AS rownum
    FROM tables.address
   WHERE (SELECT COUNT(*) FROM tables.address) = 0
     AND type_relid IS NOT NULL
)
SELECT cb.relid
      ,a.relid
  FROM tables.customer_business cb
  JOIN BUSINESS_ADDRESS a
    ON a.rownum = cb.relid;
