-- Seed address types
--
-- ANY NEW DATA ADDED AFTER INITIAL GO LIVE MUST BE ADDED IN A NEW SRC DIRECTORY
--
WITH ADDR_TYPE_DATA AS (
  SELECT s.*
        ,ROW_NUMBER() OVER() AS ord
    FROM (VALUES
            ('Physical')
           ,('Mailing')
           ,('Billing')
         ) AS s(name)
    LEFT
    JOIN tables.address_type t 
      ON s.name = t.name
   WHERE t.relid IS NULL
)
,ROW_DATA AS (
  SELECT *
    FROM ADDR_TYPE_DATA atd
    JOIN LATERAL (
          SELECT *
            FROM code.NEXT_BASE('tables.address_type'::regclass::oid, atd.name, atd.name) t
         ) ON TRUE
)
INSERT INTO tables.address_type(
  relid
 ,name
 ,ord
)
SELECT relid
      ,name
      ,ord
  FROM ROW_DATA;
