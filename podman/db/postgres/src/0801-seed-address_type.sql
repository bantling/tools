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
)
INSERT INTO tables.address_type(
  description
 ,terms
 ,name
 ,ord
)
SELECT atd.name                         AS description
      ,TO_TSVECTOR('english', atd.name) AS terms
      ,atd.*
  FROM ADDR_TYPE_DATA atd
    ON CONFLICT(name) DO
UPDATE
   SET                     ord  = excluded.ord
 WHERE tables.address_type.ord != excluded.ord;
