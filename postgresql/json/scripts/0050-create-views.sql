\c mydb

-- myapp.get_customer_addresses
--
-- return customers with their addresses as a JSONB array
CREATE OR REPLACE FUNCTION myapp.get_customer_addresses(filter JSONB) RETURNS JSONB AS
$$
  WITH PARAMS AS (
    SELECT filter ->> 'firstName'  AS first_name
          ,filter ->> 'middleName' AS middle_name
          ,filter ->> 'lastName'   AS last_name
  )
  SELECT jsonb_agg(
           myapp.jsonb_to_app_layer(to_jsonb(c)) ||
           jsonb_build_object(
             'addresses',
             (
               SELECT jsonb_agg(myapp.jsonb_to_app_layer(to_jsonb(a)))
                 FROM myapp.address a
                WHERE a.customer_rel_id = c.rel_id
             )
           )
         )
    FROM PARAMS p
        ,myapp.customer c
   WHERE ((p.first_name  IS NULL) OR (p.first_name  = c.first_name))
     AND ((p.middle_name IS NULL) OR (p.middle_name = c.middle_name))
     AND ((p.last_name   IS NULL) OR (p.last_name   = c.last_name))
$$ LANGUAGE SQL;

-- myapp.save_customer_addresses
--
-- save a customer and their addressses
-- each customer and all associated addresses must have an id that is a valid uuid
-- returns a json object containing the following:
--   - numberOfErrors: the number of customers that failed to save
--   - ids: array of ids for each failed save
CREATE OR REPLACE PROCEDURE myapp.set_customer_addresses(p_data JSONB, OUT p_res JSONB) AS
$$
BEGIN
  -- Validate data is an array
  IF jsonb_type(p_data) != 'array' THEN
    RAISE EXCEPTION 'p_data is not a json array';
  END IF:

  -- Insert/update all customers first
  BEGIN
    WITH SAVE AS (
      SELECT value #>> 'id'
        FROM jsonb_array_elements(p_data)
       WHERE value #>> 'id' IS NOT NULL
      EXCEPT
      INSERT INTO myapp.customer (
        id
       ,first_name
       ,middle_name
       ,last_name
      )
      SELECT value #>> 'id'
            ,value #>> 'firstName'
            ,value #>> 'middleName'
            ,value #>> 'lastName'
        FROM jsonb_array_elements(p_data)
       WHERE value #>> 'id' IS NOT NULL
      ON CONFLICT(id) DO
      UPDATE SET firstName  = excluded.firstName
                ,middleName = excluded.middleName
                ,lastName   = excluded.lastName
      RETURNING id
    )
    SELECT jsonb_build_object(
             'numberOfErrors', (SELECT COUNT(*) FROM s)
            ,'ids'           , jsonb_agg(s.id)
          ) res
      FROM SAVE s
      INTO p_res;
  EXCEPTION
       WHEN OTHERS THEN NULL;
  END;
END;
$$ LANGUAGE PLPGSQL;

-- myapp.get_invoice_lines
--
-- return invoices and their lines as a JSONB array
CREATE OR REPLACE FUNCTION myapp.get_invoice_lines(filter JSONB) RETURNS JSONB AS
$$
  WITH PARAMS AS (
    SELECT (filter ->> 'customerId')::UUID                    AS customer_id
          ,(filter ->> 'purchaseStartDate')::DATE             AS purchase_start_date
          ,(filter ->> 'purchaseEndDate')::DATE               AS purchase_end_date
          ,myapp.encode_product_oid(filter ->> 'productType') AS product_oid
  )
  SELECT jsonb_agg(
           myapp.jsonb_to_app_layer(to_jsonb(i)) ||
           jsonb_build_object(
             'customer',
             myapp.jsonb_to_app_layer(to_jsonb(c)),
             'lines',
             (
               SELECT jsonb_agg(myapp.jsonb_to_app_layer(to_jsonb(l)))
                 FROM myapp.invoice_line l
                WHERE l.invoice_rel_id = i.rel_id
             )
           )
         )
    FROM PARAMS p
        ,myapp.invoice i
    JOIN myapp.customer c ON c.rel_id = i.customer_rel_id
   WHERE ((p.customer_id         IS NULL) OR (p.customer_id   = c.id))
     AND ((p.purchase_start_date IS NULL) OR (i.purchased_on >= p.purchase_start_date))
     AND ((p.purchase_end_date   IS NULL) OR (i.purchased_on <= p.purchase_end_date))
     AND ((p.product_oid         IS NULL) OR EXISTS (
             SELECT 1
               FROM myapp.invoice_line l
              WHERE l.invoice_rel_id = i.rel_id
                AND l.product_oid = p.product_oid
         ))
$$ LANGUAGE SQL;

\q
