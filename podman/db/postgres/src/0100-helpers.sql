-- Helper functions that could be used in table definitions, views, or code

-- TEST(BOOLEAN, TEXT): test that a condition succeeded for cases where no exception is raised
--   P_TEST: true if test succeeded, false if it failed
--   P_MSG : string to include in exception if the test failed
-- 
-- Returns true if the condition is true, else it raises an exception with the given error message
-- It is a function so it can be used in select, making it easy and useful for unit tests
CREATE OR REPLACE FUNCTION code.TEST(P_TEST BOOLEAN, P_MSG TEXT) RETURNS BOOLEAN AS
$$
BEGIN
  IF NOT P_TEST THEN
    RAISE EXCEPTION '%', P_MSG;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Test TEST(P_TEST, P_MSG)
DO $$
DECLARE
  V_RES BOOLEAN;
  V_MSG TEXT;
BEGIN
  BEGIN
    V_RES := TRUE;
    V_RES := code.TEST(FALSE, 'TEST');
    V_RES := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'TEST' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG when P_TEST is false';
      END IF;  
  END;
  
  IF NOT V_RES THEN
    RAISE EXCEPTION 'code.TEST must die when P_TEST is false';
  END IF;
  
  BEGIN
    V_RES := FALSE;
    V_RES := code.TEST(TRUE, 'TEST');
    IF NOT VRES THEN
      RAISE EXCEPTION 'code.TEST must succeed when P_TEST is true';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'code.TEST must not die when P_TEST is true';
  END;
END;
$$ LANGUAGE plpgsql;

-- TEST(TEXT, TEXT, TEXT, TEXT, ANYELEMENT...): test a function that may raise an exception
--   P_MSG    : string to include in exception if the test failed
--   P_ERR    : expected exception text, or null if no exception is expected
--   P_RES    : expected result, or null if an exception is expected
--   P_FUNC   : string name of function
--   P_ARGS   : optional variadic args to pass to the function
--
--   NOTES:
--     1. If an exception is     expected, P_ERR must be non-null and P_RES must be null
--        If an exception is not expected, P_ERR must be     null and P_RES must be non-null 
--     2. P_RES and P_ARGS string values must be passed as a string that contains single quotes, eg the string 'foo',
--        which would be passed as an array element value of '''foo''' 
-- 
-- Returns true if invoking P_FUNC with P_ARGS returns P_RES, else it raises an exception with message P_MSG
-- It is a function so it can be used in select, making it easy and useful for unit tests
CREATE OR REPLACE FUNCTION code.TEST(P_MSG TEXT, P_ERR TEXT, P_RES TEXT, P_FUNC TEXT, P_ARGS VARIADIC TEXT[] = NULL) RETURNS BOOLEAN AS
$$
DECLARE
  V_EXPECT_ERR BOOLEAN;
  V_EXPECT_RES BOOLEAN;
  V_CALL       TEXT;
  V_RES        TEXT;
  V_ERR        TEXT;
BEGIN
  -- P_MSG cannot be NULL or EMPTY
  IF LENGTH(COALESCE(P_MSG, '')) = 0 THEN
    RAISE EXCEPTION 'P_MSG cannot be null or empty';
  END IF;
   
  -- Enforce that exactly one of P_ERR and P_RES is NON-NULL and NON-EMPTY
  V_EXPECT_ERR := NOT LENGTH(COALESCE(P_ERR, '')) = 0;
  V_EXPECT_RES := NOT LENGTH(COALESCE(P_RES, '')) = 0;
  IF V_EXPECT_ERR = V_EXPECT_RES THEN
    -- They are both NON-NULL/EMPTY
    RAISE EXCEPTION 'P_ERR and P_RES are mututally exclusive, exactly one of them must be NON-NULL and NON-EMPTY';
  END IF;

  BEGIN
    -- Construct a string function call, considering that there may be zero or more args passed to it
    SELECT 'SELECT ' || P_FUNC || '(' || (SELECT COALESCE(STRING_AGG(t, ','), '') FROM UNNEST(P_ARGS) t) || ')' INTO V_CALL;
  
    -- Execute the call
    EXECUTE V_CALL INTO V_RES;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_ERR = MESSAGE_TEXT;
      
      -- Is an exception expected?
      IF NOT V_EXPECT_ERR THEN
        RAISE EXCEPTION '%: An unexpected exception occurred: ''%''', P_MSG, V_ERR;
      END IF;
  END;
  
  -- If an exception is expected, does it have the right text?
  IF V_EXPECT_ERR THEN
    IF NOT V_ERR = P_ERR THEN
      RAISE EXCEPTION '%: The expected exception message ''%'' does not match the actual message ''%''', P_MSG, P_ERR, V_ERR;
    END IF;
    
  -- If a result is expected, is it the right result?
  ELSE
    IF NOT V_RES = P_RES THEN
      RAISE EXCEPTION '%: The expected result ''%'' does not match the actual result ''%''', P_MSG, P_RES, V_RES;
    END IF;
  END IF;
  
  -- Success
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Test TEST(P_MSG, P_ERR, P_RES, P_FUNC, P_ARGS...)
DO $$
DECLARE
  DIED BOOLEAN;
  MSG TEXT;
  V_RES BOOLEAN;
BEGIN
  -- P_MSG cannot be null
  BEGIN
    DIED := TRUE;
    SELECT code.TEST(NULL, NULL, NULL, NULL);
    DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      IF NOT MSG = 'P_MSG cannot be null or empty' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG cannot be null or empty';
      END IF;
  END;
  IF NOT DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_MSG is NULL';
  END IF;
  
  -- P_MSG cannot be empty
  BEGIN
    DIED := TRUE;
    SELECT code.TEST('', NULL, NULL, NULL);
    DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      IF NOT MSG = 'P_MSG cannot be null or empty' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG cannot be null or empty';
      END IF;
  END;
  IF NOT DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_MSG is empty';
  END IF;
  
  -- Only one of P_ERR AND P_RES can be null/empty
  BEGIN
    DIED := TRUE;
    SELECT code.TEST('P_MSG', NULL, NULL, NULL);
    DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      IF NOT MSG = 'P_ERR and P_RES are mututally exclusive, exactly one of them must be NON-NULL and NON-EMPTY' THEN
        RAISE EXCEPTION 'code.TEST must die with P_ERR and P_RES are mututally exclusive';
      END IF;
  END;
  IF NOT DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_ERR and P_RES are both NULL';
  END IF;
  
  -- Only one of P_ERR and P_RES can be non-null/empty
  BEGIN
    DIED := TRUE;
    SELECT code.TEST('P_MSG', '1', '2', NULL);
    DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      IF NOT MSG = 'P_ERR and P_RES are mututally exclusive, exactly one of them must be NON-NULL and NON-EMPTY' THEN
        RAISE EXCEPTION 'code.TEST must die with P_ERR and P_RES are mututally exclusive';
      END IF;
  END;
  IF NOT DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_ERR and P_RES are both non-NULL';
  END IF;
  
  -- Test calling PI()
  BEGIN
    SELECT code.TEST('P_MSG', NULL, PI()::TEXT, 'PI') INTO V_RES;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'code.TEST must succeed for PI()';
  END;
  IF NOT V_RES THEN
    RAISE EXCEPTION 'code.TEST PI() must equal PI';
  END IF;
  
  -- Test calling COALESCE(NULL, 1)
  BEGIN
    SELECT code.TEST('P_MSG', NULL, '1', 'COALESCE', 'NULL', '1') INTO V_RES;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'code.TEST must succeed for COALESCE(NULL, 1)';
  END;
  IF NOT V_RES THEN
    RAISE EXCEPTION 'code.TEST COALESCE(NULL, 1) must equal 1';
  END IF;
  
  -- Test error calling COALESCE(), where the error message provided IS correct
  BEGIN
    DIED := TRUE;
    SELECT code.TEST('SYNERR', 'syntax error at or near ")"', NULL, 'COALESCE') INTO V_RES;
    DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      RAISE EXCEPTION 'code.TEST COALESCE() DIED when we provided correct error message: %', MSG;
  END;
  IF DIED THEN
    RAISE EXCEPTION 'code.TEST must catch and handle COALESCE() exception when we provide correct error message';
  END IF;
  
  -- Test error calling COALESCE(), where the error message provided IS NOT correct
  BEGIN
    DIED := TRUE;
    SELECT code.TEST('SYNERR', 'wrong error message', NULL, 'COALESCE') INTO V_RES;
    DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      IF NOT MSG = 'SYNERR: The expected exception message ''wrong error message'' does not match the actual message ''syntax error at or near ")"''' THEN
        RAISE EXCEPTION 'code.TEST COALESCE() did not return incorrect error message';
      END IF;
  END;
  IF NOT DIED THEN
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
SELECT code.TEST(code.IIF(true , 'a'::TEXT, 'b') = 'a', 'IIF must return a');
SELECT code.TEST(code.IIF(false, 'a'::TEXT, 'b') = 'b', 'IIF must return b');


-- BLANK_WS: a version of CONCAT_WS that treats empty strings like nulls, and coalesces consecutive empty/nulls
--   P_SEP : The separator string
--   P_STRS: The strings to place a separator between
--
-- Returns each non-null non-empty string in P_STRS, separaated by P_SEP
-- Unlike CONCAT_WS, the nulls and empty strings are removed first, eliminating consecutive separators 
CREATE OR REPLACE FUNCTION code.BLANK_WS(P_SEP TEXT, P_STRS VARIADIC TEXT[] = NULL) RETURNS TEXT AS
$$
  SELECT STRING_AGG(strs, P_SEP)
    FROM (SELECT UNNEST(P_STRS) strs) t
   WHERE LENGTH(COALESCE(strs, '')) > 0
$$ LANGUAGE SQL IMMUTABLE LEAKPROOF PARALLEL SAFE;

-- Test BLANK_WS
SELECT code.TEST(code.BLANK_WS('-', null, 'a', '', 'b') = 'a-b', 'BLANK_WS must return a-b');
SELECT code.TEST(code.BLANK_WS('-', null, null, 'a', '', '', 'b', '', null, 'c') = 'a-b-c', 'BLANK_WS must return a-b-c');


-- TO_8601 converts a TIMESTAMP into an ISO 8601 string of the form
-- YYYY-MM-DDTHH:MM:SS.sssZ
-- 123456789012345678901234
-- This is a 24 char string
CREATE OR REPLACE FUNCTION code.TO_8601(P_TS TIMESTAMP = NOW() AT TIME ZONE 'UTC') RETURNS VARCHAR(24) AS
$$
  SELECT TO_CHAR(COALESCE(P_TS, NOW() AT TIME ZONE 'UTC'), 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
$$ LANGUAGE SQL IMMUTABLE LEAKPROOF PARALLEL SAFE;

-- Test TO_8601
SELECT code.TEST(code.TO_8601() = TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'), 'TO_8601() must return NOW');
SELECT code.TEST(code.TO_8601(NULL) = TO_CHAR(NOW() AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'), 'TO_8601(NULL) must return NOW');
SELECT code.TEST(code.TO_8601(NOW() AT TIME ZONE 'UTC' - INTERVAL '1 DAY') = TO_CHAR(NOW() AT TIME ZONE 'UTC' - INTERVAL '1 DAY', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'), 'TO_8601(NULL) must return NOW');

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

DO $$
DECLARE
  TMP BIGINT;
  MSG TEXT;
BEGIN
  BEGIN
    SELECT code.RELID_TO_ID(NULL) INTO TMP;
    ASSERT 'RELID_TO_ID(NULL) must fail';
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      ASSERT MSG = 'P_RELID cannot be null or 0';
  END;
  
  BEGIN
    SELECT code.RELID_TO_ID(0) INTO TMP;
    ASSERT 'RELID_TO_ID(0) must fail';
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      ASSERT MSG = 'P_RELID cannot be null or 0';
  END;
  
  SELECT COUNT(code.TEST(code.RELID_TO_ID(column1) = column2, CONCAT_WS(' ', 'expected', column2, 'got', column1)))
    INTO TMP
    FROM (VALUES
           (1::BIGINT                , '1')
          ,(10                       , 'A')
          ,(10+25                    , 'Z')
          ,(10+26                    , 'a')
          ,(10+26+25                 , 'z')
          ,(10+26+26                 , '10')
          ,(10_000_000_000           , 'Aukyoa')
          ,(9_223_372_036_854_775_807, 'AzL8n0Y58m7')
         ) t;
END;
$$ LANGUAGE plpgsql;
