-- Helper functions that could be used in table definitions, views, or code

-- TEST: test that a condition succeeded
--   P_TEST: true if test succeeded, false if it failed
--   P_STR : string to include in exception if the test failed
-- 
-- Returns true if the condition is true, else it raises an exception with the given error message
-- It is a function so it can be used in select, making it easy and useful for unit tests
CREATE OR REPLACE FUNCTION code.TEST(P_TEST BOOLEAN, P_STR TEXT) RETURNS BOOLEAN AS
$$
BEGIN
  IF NOT P_TEST THEN
    RAISE EXCEPTION '%', P_STR;
  END IF;
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Test TEST
DO $$
DECLARE
  MSG TEXT;
BEGIN
  BEGIN
    IF code.TEST(FALSE, 'TEST') THEN
      RAISE EXCEPTION 'code.ASSERT must die when P_TEST is false';
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS MSG = MESSAGE_TEXT;
      ASSERT MSG = 'TEST';
  END;
  
  BEGIN
    IF NOT code.TEST(TRUE, 'TEST') THEN
      RAISE EXCEPTION 'code.ASSERT must succeed when P_TEST is true';
    END IF;
  END;
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

