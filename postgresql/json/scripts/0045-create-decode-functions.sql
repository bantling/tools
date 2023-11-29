\c mydb

-- encode_product_name
--
-- convert a product name (table name without a schema) into a product OID
CREATE OR REPLACE FUNCTION myapp.encode_product_oid(name TEXT) RETURNS OID AS
$$
  SELECT CASE name
           WHEN 'book'  THEN 'myapp.book'::regclass::oid
           WHEN 'movie' THEN 'myapp.movie'::regclass::oid
           ELSE NULL
          END;
$$ LANGUAGE SQL;

-- decode_product_name
--
-- convert a OID into a product name (table name without a schema)
CREATE OR REPLACE FUNCTION myapp.decode_product_oid(id OID) RETURNS TEXT AS
$$
  SELECT CASE id
           WHEN 'myapp.book'::regclass::oid  THEN 'book'
           WHEN 'myapp.movie'::regclass::oid THEN 'movie'
           ELSE NULL
          END;
$$ LANGUAGE SQL;

-- app_layer_to_jsonb
--
-- jb must be an object
-- 1. If productType key exists, translate it to key product_oid and convert value to product OID
-- 2. Translate all lower came case keys part1Part2Part3 into snake case keys part1_part2_part3
CREATE OR REPLACE FUNCTION myapp.app_layer_to_jsonb(jb JSONB) RETURNS JSONB AS
$$
  SELECT jsonb_object_agg(key, value)
    FROM (
     SELECT LOWER(REGEXP_REPLACE(key, E'([A-Z])', E'\_\\1','g')) key
            ,value
       FROM (
         SELECT CASE WHEN key = 'productType' THEN 'productOid' ELSE key END AS key
               ,CASE WHEN key = 'productType' THEN to_jsonb(myapp.encode_product_oid(value #>> '{}')::INTEGER) ELSE value END AS value
           FROM jsonb_each(jb) j
        ) t
    ) u;
$$ LANGUAGE SQL;

-- jsonb_to_app_layer
--
-- jb musyt be an object
-- 1. Remove all keys from a jsonb object where key name name ends in 'rel_id'.
-- 2. If a product_type key exists, translate it to key productType and convert value to product string
-- 3. Translate all snake case keys part1_part2_part3... into lower camel case part1Part2Part3...
-- Use this function to make the jsonb data from a table match what application layer expects.
CREATE OR REPLACE FUNCTION myapp.jsonb_to_app_layer(jb JSONB) RETURNS JSONB AS
$$
  SELECT jsonb_object_agg(key, value) jbo
  FROM (
    SELECT LOWER(LEFT(ucamel, 1)) || RIGHT(ucamel, -1) key
          ,value
      FROM (
        SELECT REPLACE(INITCAP(REPLACE(key, '_', ' ')), ' ', '') ucamel
              ,value
          FROM (
            SELECT CASE WHEN key = 'product_oid' THEN 'product_type' ELSE key END AS key
                  ,CASE WHEN key = 'product_oid' THEN to_jsonb(myapp.decode_product_oid((value #>> '{}')::OID)) ELSE value END AS value
              FROM jsonb_each(jb) j
             WHERE KEY NOT LIKE '%rel_id'
          ) t
      ) u
  ) v;
$$ LANGUAGE SQL;

\q
