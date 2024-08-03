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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
          END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
           WHEN 'CO' -- Colorado
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
            END
           WHEN 'CT' -- Connecticut
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
            END
           WHEN 'DC' -- District of Columbia
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
            END
           WHEN 'DE' -- Delaware
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
            END
           WHEN 'FL' -- Florida
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
            END
           WHEN 'GA' -- Georgia
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
            END
           WHEN 'GU' -- Guam
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
            END
           WHEN 'HI' -- Hawaii
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
            END
           WHEN 'ID' -- Idaho
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
            END
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
