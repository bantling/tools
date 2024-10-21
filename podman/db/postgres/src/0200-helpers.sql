-- Helper functions that could be used in table definitions, views, or code

-- TEST(BOOLEAN, TEXT): test that a condition succeeded for cases where no exception is raised
--   P_MSG : string exception message if the test failed
--   P_TEST: true if test succeeded, false if it failed
-- 
-- Returns true if the condition is true, else it raises an exception with the given error message
-- It is a function so it can be used in select, making it easy and useful for unit tests
CREATE OR REPLACE FUNCTION code.TEST(P_MSG TEXT, P_TEST BOOLEAN) RETURNS BOOLEAN AS
$$
BEGIN
  CASE
    WHEN  P_MSG IS NULL THEN
      RAISE EXCEPTION 'P_MSG CANNOT BE NULL';

    WHEN NOT COALESCE(P_TEST, FALSE) THEN
      RAISE EXCEPTION '%', P_MSG;

    ELSE
      RETURN TRUE;
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Test TEST(P_MSG, P_TEST)
DO $$
DECLARE
  V_DIED BOOLEAN;
  V_MSG  TEXT;
BEGIN
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST(NULL, NULL);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'P_MSG CANNOT BE NULL' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG CANNOT BE NULL';
      END IF;  
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_MSG is NULL';
  END IF;
  
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('TEST', NULL);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'TEST' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG when P_TEST is null';
      END IF;  
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_TEST is null';
  END IF;
  
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('TEST', FALSE);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'TEST' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG when P_TEST is false';
      END IF;  
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_TEST is false';
  END IF;
  
  BEGIN
    IF NOT code.TEST('TEST', TRUE) THEN
      RAISE EXCEPTION 'code.TEST must succeed when P_TEST is true';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'code.TEST must not die when P_TEST is true';
  END;
END;
$$ LANGUAGE plpgsql;

-- TEST(TEXT, TEXT, TEXT, ANYELEMENT...): test a function for a case that raises an exception
--   P_MSG    : string to include in exception if the test failed
--   P_ERR    : expected exception text
--   P_FUNC   : string name of function
--   P_ARGS   : optional variadic args to pass to the function
--
--   NOTE: 
--   P_ARGS are string values that are concatanated into an SQL string of the following form:
--     SELECT <FUNCTION_NAME>(ARG1, ARG2, ...)
--
--   This means if you want to form the string SELECT FN('foo', true, 1), you would need to
--   call TEST('msg', 'error text', 'FN', '''foo''', 'true', '1') 
-- 
-- Returns true if invoking P_FUNC with P_ARGS raises an exception with message P_ERR
-- It is a function so it can be used in select, making it easy and useful for unit tests
CREATE OR REPLACE FUNCTION code.TEST(P_MSG TEXT, P_ERR TEXT, P_FUNC TEXT, P_ARGS VARIADIC TEXT[] = NULL) RETURNS BOOLEAN AS
$$
DECLARE
  V_CALL TEXT;
  V_RES  TEXT;
  V_ERR  TEXT;
  V_DIED BOOLEAN;
BEGIN
  -- P_MSG cannot be NULL or EMPTY
  IF LENGTH(COALESCE(P_MSG, '')) = 0 THEN
    RAISE EXCEPTION 'P_MSG cannot be null or empty';
  END IF;
  
  -- P_ERR cannot be NULL or EMPTY
  IF LENGTH(COALESCE(P_ERR, '')) = 0 THEN
    RAISE EXCEPTION 'P_ERR cannot be null or empty';
  END IF;

  BEGIN
    -- Construct a string function call, considering that there may be zero or more args passed to it
    SELECT 'SELECT ' || P_FUNC || '(' || (SELECT COALESCE(STRING_AGG(t, ','), '') FROM UNNEST(P_ARGS) t) || ')' INTO V_CALL;
  
    -- Execute the call
    V_DIED := TRUE;
    EXECUTE V_CALL INTO V_RES;
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_ERR = MESSAGE_TEXT;
  END;
  
  CASE
    -- Did an exception occur?
    WHEN NOT V_DIED
    THEN RAISE EXCEPTION '%s: An exception did not occur', P_MSG;
  
    -- If an exception is expected, does it have the right text?
    WHEN NOT V_ERR = P_ERR
    THEN RAISE EXCEPTION '%: The expected exception message ''%'' does not match the actual message ''%''', P_MSG, P_ERR, V_ERR;
    
    ELSE NULL;
  END CASE;
  
  -- Success
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Test TEST(P_MSG, P_ERR, P_FUNC, P_ARGS...)
DO $$
DECLARE
  V_DIED BOOLEAN;
  V_ERR  TEXT;
  V_MSG TEXT;
  V_RES  TEXT;
BEGIN
  -- P_MSG cannot be null
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST(NULL, NULL, NULL);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'P_MSG cannot be null or empty' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG cannot be null or empty';
      END IF;
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_MSG is NULL';
  END IF;
  
  -- P_MSG cannot be empty
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('', NULL, NULL);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'P_MSG cannot be null or empty' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG cannot be null or empty';
      END IF;
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_MSG is empty';
  END IF;
  
  -- Test error calling COALESCE(), where the error message provided IS correct
  BEGIN
    SELECT code.TEST('SYNERR', 'syntax error at or near ")"', 'COALESCE') INTO V_RES;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      RAISE EXCEPTION 'code.TEST COALESCE() DIED when we provided correct error message: %', V_MSG;
  END;
  
  -- Test error calling COALESCE(), where the error message provided IS NOT correct
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('SYNERR', 'wrong error message', 'COALESCE') INTO V_RES;
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'SYNERR: The expected exception message ''wrong error message'' does not match the actual message ''syntax error at or near ")"''' THEN
        RAISE EXCEPTION 'code.TEST COALESCE() did not return incorrect error message';
      END IF;
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when COALESCE() fails and we provided wrong error message';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- IIF: A useful polymorphic function some other vendors have that Postgres lacks
--   P_EXPR     : A boolean expression
--   P_TRUE_VAL : value to return if P_EXPR is true
--   P_FALSE_VAL: value to return if P_EXPR is false
--
-- Returns P_TRUE_VAL if P_EXPR is true, else P_FALSE_VAL
CREATE OR REPLACE FUNCTION code.IIF(P_EXPR BOOLEAN, P_TRUE_VAL ANYELEMENT, P_FALSE_VAL ANYELEMENT) RETURNS ANYELEMENT AS
$$
  SELECT CASE WHEN P_EXPR THEN P_TRUE_VAL ELSE P_FALSE_VAL END
$$ LANGUAGE SQL IMMUTABLE LEAKPROOF PARALLEL SAFE;

-- Test IIF
SELECT DISTINCT code.TEST('IIF must return ' || res, code.IIF(expr, tval, fval) = res) iif
  FROM (VALUES
        (TRUE,  'a'::TEXT, 'b', 'a'),
        (FALSE, 'a'::TEXT, 'b', 'b')
       ) AS t (expr, tval, fval, res);

-- NEMPTY_WS: a version of CONCAT_WS that treats empty strings like nulls, and coalesces consecutive empty/nulls
--   P_SEP : The separator string
--   P_STRS: The strings to place a separator between
--
-- Returns each non-null non-empty string in P_STRS, separated by P_SEP
-- Unlike CONCAT_WS, the nulls and empty strings are removed first, eliminating consecutive separators 
CREATE OR REPLACE FUNCTION code.NEMPTY_WS(P_SEP TEXT, P_STRS VARIADIC TEXT[] = NULL) RETURNS TEXT AS
$$
  SELECT STRING_AGG(strs, P_SEP)
    FROM (SELECT UNNEST(P_STRS) strs) t
   WHERE LENGTH(COALESCE(strs, '')) > 0
$$ LANGUAGE SQL IMMUTABLE LEAKPROOF PARALLEL SAFE;

-- Test NBLANK_WS
SELECT DISTINCT code.TEST(msg, code.NEMPTY_WS('-', VARIADIC args) = res) nempty_ws
  FROM (VALUES
         ('NEMPTY_WS must return a-b'    , ARRAY[NULL, 'a' , '' , 'b'                       ], 'a-b'),
         ('NEMPTY_WS must return a-b-c'  , ARRAY[NULL, NULL, 'a', '', '', 'b', '', NULL, 'c'], 'a-b-c'),
         ('NEMPTY_WS must return a-b-c-d', ARRAY['a' , 'b' , 'c', 'd'                       ], 'a-b-c-d')
       ) AS t (msg, args, res);

-- TO_8601 converts a TIMESTAMP into an ISO 8601 string of the form
-- YYYY-MM-DDTHH:MM:SS.sssZ
-- 123456789012345678901234
-- This is a 24 char string
CREATE OR REPLACE FUNCTION code.TO_8601(P_TS TIMESTAMP = NOW() AT TIME ZONE 'UTC') RETURNS VARCHAR(24) AS
$$
  SELECT TO_CHAR(COALESCE(P_TS, NOW() AT TIME ZONE 'UTC'), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
$$ LANGUAGE SQL IMMUTABLE LEAKPROOF PARALLEL SAFE;

-- Test TO_8601
SELECT DISTINCT code.TEST(msg, code.IIF(ARRAY_LENGTH(ARG, 1) = 0, code.TO_8601(), code.TO_8601(ARG[1])) = res)
  FROM (VALUES
         ('TO_8601() must return NOW'                   , ARRAY[]::TIMESTAMP[]                              , TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')),
         ('TO_8601(NULL) must return NOW'               , ARRAY[NULL]::TIMESTAMP[]                          , TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')),
         ('TO_8601(NOW - 1 DAY) must return NOW - 1 DAY', ARRAY[NOW() AT TIME ZONE 'UTC' - INTERVAL '1 DAY'], TO_CHAR(NOW() AT TIME ZONE 'UTC' - INTERVAL '1 DAY', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'))
       ) AS t(msg, arg, res);

-- RELID_TO_ID converts a BIGINT to a base 62 string with a maximum of 11 chars
-- Maximum signed BIGINT value is 9_223_372_036_854_775_807 -> AzL8n0Y58m7
--                                                             12345678901
-- Raises an exception if P_RELID is NULL or 0, since valid relids start at 1
CREATE OR REPLACE FUNCTION code.RELID_TO_ID(P_RELID BIGINT) RETURNS VARCHAR(11) AS
$$
DECLARE
  RELID BIGINT := P_RELID;
  DIGIT CHAR;
  ID VARCHAR(11) = '';
  RMDR INT;
BEGIN
  IF COALESCE(RELID, 0) = 0 THEN
    RAISE EXCEPTION 'P_RELID cannot be null or 0';
  END IF;

  WHILE RELID > 0 LOOP
    RMDR  = RELID % 62;
    CASE
      WHEN RMDR < 10      THEN DIGIT = CHR(ASCII('0') + RMDR          );
      WHEN RMDR < 10 + 26 THEN DIGIT = CHR(ASCII('A') + RMDR - 10     );
      ELSE                     DIGIT = CHR(ASCII('a') + RMDR - 10 - 26);
    END CASE;
    
    -- Add digits to the front of the string, modulus gives us the digits from least to most significant
    -- Eg for the relid 123, we get the digits 3,2,1
    ID    = DIGIT || ID;
    RELID = RELID /  62;
  END LOOP;
  
  RETURN ID;
END;
$$ LANGUAGE plpgsql IMMUTABLE LEAKPROOF PARALLEL SAFE;

--- Test RELID_TO_ID
SELECT DISTINCT * FROM (
  SELECT code.TEST('RELID_TO_ID(NULL)'            , 'P_RELID cannot be null or 0', 'code.RELID_TO_ID', 'NULL') relid_to_id
  UNION  ALL
  SELECT code.TEST('RELID_TO_ID(0)'               , 'P_RELID cannot be null or 0', 'code.RELID_TO_ID', '0'   )
  UNION ALL
  SELECT code.TEST('RELID_TO_ID must return ' || i, code.RELID_TO_ID(r) = i)
    FROM (VALUES
           (1                        , '1'          ),
           (9                        , '9'          ),
           (10                       , 'A'          ),
           (10 + 25                  , 'Z'          ), -- 35
           (10 + 26                  , 'a'          ), -- 36
           (10 + 26 + 25             , 'z'          ), -- 61
           (10 + 26 + 26             , '10'         ), -- 62
           (10_000_000_000           , 'Aukyoa'     ), -- = 10 * 62^5      + (36 + 20) * 62^4     + (36 + 10) * 62^3   + (36 + 24) * 62^2 + (36 + 14) * 62 + 36
                                                       -- = 10 * 916132832 + 56        * 14776336 + 46        * 238328 + 60        * 3844 + 50        * 62 + 36
           (9_223_372_036_854_775_807, 'AzL8n0Y58m7')  -- = 10 * 62^10              + (10 + 26 + 25) * 62^9              + (10 + 11) * 62^8            + 8 * 62^7          + (10 + 26 + 13) * 62^6        + 0 * 62^5      + (10 + 24) * 62^4     + 5 * 62^3   + 8 * 62^2 + (10 + 26 + 12) * 62 + 7
                                                       -- = 10 * 839299365868340224 + 61             * 13537086546263552 + 21 *        218340105584896 + 8 * 3521614606208 + 49             * 56800235584 + 0 * 916132832 + 34        * 14776336 + 5 * 238328 + 8 * 3844 + 48             * 62 + 7    
        ) AS t(r, i)
) t;

-- ID_TO_RELID converts a base 62 string with a maximum of 11 chars to a BIGINT
-- Maximum ID is AzL8n0Y58m7 -> signed BIGINT value is 9_223_372_036_854_775_807 
--               12345678901
-- Raises an exception if P_ID is NULL or 0, since valid ids start at 1 
CREATE OR REPLACE FUNCTION code.ID_TO_RELID(P_ID VARCHAR(11)) RETURNS BIGINT AS
$$
DECLARE
  V_DIGIT       CHAR;
  V_ASCII_DIGIT INT;
  V_RELID       BIGINT := 0;
BEGIN
  -- P_ID cannot be null or empty
  IF LENGTH(COALESCE(P_ID,'')) = 0 THEN
    RAISE EXCEPTION 'P_ID cannot be null or empty';
  END IF;
  
  -- P_ID must be >= '1' and <= 'AzL8n0Y58m7'. Use C collation for ASCII sorting. 
  IF (LPAD(P_ID, 11, '00000000000') COLLATE "C" < '00000000001' COLLATE "C") OR (LPAD(P_ID, 11, '00000000000') COLLATE "C" > 'AzL8n0Y58m7' COLLATE "C") THEN
    RAISE EXCEPTION 'P_ID must be in the range [1 .. AzL8n0Y58m7]';
  END IF;

  FOREACH V_DIGIT IN ARRAY regexp_split_to_array(P_ID, '')
  LOOP
    -- Get the ASCII numeric value to guarantee an ASCII comparison 
    V_ASCII_DIGIT = ASCII(V_DIGIT);
    V_RELID = V_RELID * 62;
    
    CASE
      WHEN V_ASCII_DIGIT >= ASCII('0') AND V_ASCII_DIGIT <= ASCII('9') THEN V_RELID = V_RELID +           (V_ASCII_DIGIT - ASCII('0'));
      WHEN V_ASCII_DIGIT >= ASCII('A') AND V_ASCII_DIGIT <= ASCII('Z') THEN V_RELID = V_RELID + 10 +      (V_ASCII_DIGIT - ASCII('A'));
      ELSE                                                                  V_RELID = V_RELID + 10 + 26 + (V_ASCII_DIGIT - ASCII('a'));
    END CASE;
  END LOOP;
  
  RETURN V_RELID;
END;
$$ LANGUAGE plpgsql IMMUTABLE LEAKPROOF PARALLEL SAFE;

--- Test ID_TO_RELID
SELECT DISTINCT * FROM (
  SELECT code.TEST('ID_TO_RELID(NULL)'           , 'P_ID cannot be null or empty'                , 'code.ID_TO_RELID', 'NULL') id_to_relid
  UNION  ALL
  SELECT code.TEST('ID_TO_RELID('''')'           , 'P_ID cannot be null or empty'                , 'code.ID_TO_RELID', '''''')
  UNION  ALL
  SELECT code.TEST('ID_TO_RELID(''0'')'          , 'P_ID must be in the range [1 .. AzL8n0Y58m7]', 'code.ID_TO_RELID', '''0''')
  UNION  ALL
  SELECT code.TEST('ID_TO_RELID(''-1'')'         , 'P_ID must be in the range [1 .. AzL8n0Y58m7]', 'code.ID_TO_RELID', '''-1''')
  UNION  ALL
  SELECT code.TEST('ID_TO_RELID(''AzL8n0Y58m8'')', 'P_ID must be in the range [1 .. AzL8n0Y58m7]', 'code.ID_TO_RELID', '''AzL8n0Y58m8''')
  UNION ALL
  SELECT code.TEST('ID_TO_RELID must return ' || r, code.ID_TO_RELID(i) = r)
    FROM (VALUES
           ('1'          , 1                        ),
           ('9'          , 9                        ),
           ('A'          , 10                       ),
           ('Z'          , 10 + 25                  ),
           ('a'          , 10 + 26                  ),
           ('z'          , 10 + 26 + 25             ),
           ('10'         , 10 + 26 + 26             ),
           ('Aukyoa'     , 10_000_000_000           ),
           ('AzL8n0Y58m7', 9_223_372_036_854_775_807)    
        ) AS t(i, r)
) t;

-- NEXT_BASE gets the next relid by inserting an entry into base
-- P_TBL is the table oid of the table to insert into
-- P_DESC is the description
-- P_TERMS is the terms
-- P_EXTRA is the extra
-- Returns all columns of the new row
--
-- Invoke by using a statement like SELECT code.NEXT_BASE('tables.country'::regclass::oid);
CREATE OR REPLACE FUNCTION code.NEXT_BASE(P_TBL OID, P_DESC TEXT = NULL, P_TERMS TEXT = NULL, P_EXTRA JSONB = NULL) RETURNS tables.base AS
$$
  INSERT INTO tables.base(
              tbloid
             ,version
             ,description
             ,terms
             ,extra
             ,created
             ,modified
           )
    VALUES (
              P_TBL
             ,1
             ,P_DESC
             ,TO_TSVECTOR('english', P_TERMS)
             ,P_EXTRA
             ,NOW() AT TIME ZONE 'UTC'
             ,NOW() AT TIME ZONE 'UTC'
           )
 RETURNING *;
$$ LANGUAGE sql;
