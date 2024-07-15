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

, GEN_ROWS AS (
  SELECT p.*
        ,generate_series(1, num_rows) row_num
    FROM PARAMS p
)
-- SELECT * FROM GEN_ROWS;
--  num_rows | num_address_types | num_countries | row_num 
--  ---------+-------------------+---------------+---------
--         5 |                 3 |             3 |       1
--         5 |                 3 |             3 |       2
--         5 |                 3 |             3 |       3
--         5 |                 3 |             3 |       4
--         5 |                 3 |             3 |       5
-- (5 rows)

, GEN_ADDRESS_COUNTRY_RELID AS (
  SELECT NULLIF((random() * d.num_address_types)::int, 0)      address_type_relid -- null = person, else = business
        ,      (random() * (d.num_countries     - 1) + 1)::int country_relid
    FROM GEN_ROWS d
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

, GEN_NUM_REGIONS AS (
  SELECT d.*
        ,NULLIF((SELECT COUNT(*) FROM tables.region r WHERE r.country_relid = d.country_relid), 0) num_regions
    FROM GEN_ADDRESS_COUNTRY_RELID d
)
-- SELECT * FROM GEN_NUM_REGIONS;
--  address_type_relid | country_relid | num_regions 
-- --------------------+---------------+-------------
--                   2 |             1 |            
--                     |             2 |          13
--                     |             3 |            
--                   2 |             3 |            
--                   2 |             4 |          56
-- (5 rows)

, GEN_DATA_REGION_RELID AS (
  SELECT d.*
        ,((random() * d.num_regions - 1) + 1)::int region_relid
    FROM GEN_NUM_REGIONS d
)
-- SELECT * FROM GEN_DATA_REGION_RELID;
--  address_type_relid | country_relid | num_regions | region_relid 
-- --------------------+---------------+-------------+--------------
--                   2 |             2 |          13 |            6
--                   2 |             2 |          13 |           12
--                   1 |             2 |          13 |            5
--                     |             4 |          56 |            6
--                   2 |             4 |          56 |           34
-- (5 rows)

, GEN_MAILING_CODE AS (
  SELECT d.*
        ,CASE c.code_2
         WHEN 'CA' THEN
           CASE r.code
           WHEN 'AB' THEN 'T'
           WHEN 'BC' THEN 'T'
           WHEN 'MB' THEN 'T'
           WHEN 'NB' THEN 'T'
           WHEN 'NL' THEN 'T'
           WHEN 'NT' THEN 'T'
           WHEN 'NS' THEN 'T'
           WHEN 'NU' THEN 'T'
           WHEN 'ON' THEN 'T'
           WHEN 'PE' THEN 'T'
           WHEN 'QC' THEN 'T'
           WHEN 'SK' THEN 'T'
           -- YT
           ELSE
           END 
         WHEN 'CX' THEN '6798' 
         WHEN 'US' THEN
           CASE r.code
           WHEN 'AL' THEN
           END
         END mailing_code
    FROM GEN_DATA_REGION_RELID d
    JOIN tables.country c
      ON c.relid = d.country_relid
    JOIN tables.region  r
      ON r.country_relid = c.relid
     AND r.relid = d.region_relid

, GEN_ADDRESS AS (
  SELECT d.address_type_relid AS type_relid
        ,d.country_relid
        ,d.region_relid
        ,gen_random_uuid()    AS id
        ,1                    AS version
        ,current_timestamp    AS created
        ,current_timestamp    AS changed
        ,'Cooks Brook'        AS city
        ,'123 Sesame St'      AS address
        ,CASE WHEN d.address_type_relid IS NOT NULL THEN 'Door 5' END AS address_2
        ,CASE WHEN d.address_type_relid IS NOT NULL THEN 'Stop 6' END AS address_3
        ,CASE WHEN d.has_mailing_code THEN 
    FROM GEN_DATA_REGION_RELID d
)
-- SELECT * FROM GEN_ADDRESS
--  type_relid | country_relid | region_relid |                  id                  | version |            created            |            changed            |    city     |    address    | address_2 | address_3 
-- ------------+---------------+--------------+--------------------------------------+---------+-------------------------------+-------------------------------+-------------+---------------+-----------+-----------
--             |             3 |              | 3d835a92-7a83-4569-b882-84e5c1569c41 |       1 | 2024-07-14 19:28:15.849933+00 | 2024-07-14 19:28:15.849933+00 | Cooks Brook | 123 Sesame St |           | 
--           1 |             2 |           13 | 88f70390-201c-4269-8766-3c58c707a145 |       1 | 2024-07-14 19:28:15.849933+00 | 2024-07-14 19:28:15.849933+00 | Cooks Brook | 123 Sesame St | Door 5    | Stop 6
--           2 |             1 |           13 | 7c965fbb-4efa-48ad-8667-44504c88968f |       1 | 2024-07-14 19:28:15.849933+00 | 2024-07-14 19:28:15.849933+00 | Cooks Brook | 123 Sesame St | Door 5    | Stop 6
--           1 |             2 |           38 | fc8b40f4-e787-4192-8a53-093490a00398 |       1 | 2024-07-14 19:28:15.849933+00 | 2024-07-14 19:28:15.849933+00 | Cooks Brook | 123 Sesame St | Door 5    | Stop 6
--           3 |             3 |              | 8e4d3996-c075-4450-bece-11f47bb71d69 |       1 | 2024-07-14 19:28:15.849933+00 | 2024-07-14 19:28:15.849933+00 | Cooks Brook | 123 Sesame St | Door 5    | Stop 6
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
