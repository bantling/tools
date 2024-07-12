-- Seed addresses
  WITH PARAMS AS (
    SELECT 5 num_rows
          ,(SELECT COUNT(*) FROM tables.address_type) num_types
  )
  ,GEN_ROWS AS (
    SELECT *
      FROM PARAMS
          ,generate_series(1, (SELECT num_rows FROM PARAMS))
  )
  ,GEN_DATA AS (
    SELECT (random() * (num_types - 1))::int + 1 typ
      FROM GEN_ROWS
  )
  SELECT typ
    FROM GEN_DATA;


SELECT typ
  FROM (SELECT (random() * ()::int typ
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
