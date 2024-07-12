-- Seed addresses
WITH PARAMS AS (
  SELECT 5 num_addresses
)
,GEN_TYPES AS (
  SELECT (random() * (SELECT COUNT(*) FROM tables.address_type))::int typ
        ,generate_series(1, (SELECT num_addresses FROM PARAMS))
)
SELECT typ
  FROM GEN_TYPES;


SELECT typ
  FROM (SELECT (random() * (SELECT COUNT(*) FROM tables.address_type))::int typ
      , generate_series(1, 5)) t;
INSERT INTO tables.address(
   id
  ,version
  ,ord
  ,created
  ,changed
) VALUES
  (
  );
