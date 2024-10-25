-- Seed address types
WITH ADDR_TYPE_DATA AS (
  SELECT name
        ,ROW_NUMBER() OVER() AS ord
    FROM (VALUES
            ('Physical')
           ,('Mailing')
           ,('Billing')
         ) AS t(name)
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
