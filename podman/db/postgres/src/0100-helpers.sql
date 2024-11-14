-- Helper functions that could be used in table definitions, views, or code

-- TEST(TEXT, BOOLEAN): test that a condition succeeded for cases where no exception is raised
--   P_MSG : string exception message if the test failed (cannot be null or empty)
--   P_TEST: true if test succeeded, null or false if it failed
-- 
-- Returns true if the condition is true, else it raises an exception with the given error message
-- It is a function so it can be used in select, making it easy and useful for unit tests
CREATE OR REPLACE FUNCTION code.TEST(P_MSG TEXT, P_TEST BOOLEAN) RETURNS BOOLEAN AS
$$
BEGIN
  CASE
    WHEN LENGTH(COALESCE(P_MSG, '')) = 0 THEN
      RAISE EXCEPTION 'P_MSG cannot be null or empty';

    WHEN NOT COALESCE(P_TEST, FALSE) THEN
      RAISE EXCEPTION '%', P_MSG;

    ELSE
      RETURN TRUE;
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- TEST(TEXT, TEXT): test a function for a case that raises an exception
--   P_ERR   : expected exception text (cannot be null or empty)
--   P_QUERY : string query to execute (cannot be null or empty)
-- 
-- Returns true if executing P_QUERY raises an exception with message P_ERR
-- It is a function so it can be used in select, making it easy and useful for unit tests
-- If the query does not fail, or fails with a different exception message, then
-- an exception is raised with P_ERR and P_QUERY in the text
CREATE OR REPLACE FUNCTION code.TEST(P_ERR TEXT, P_QUERY TEXT) RETURNS BOOLEAN AS
$$
DECLARE
  V_ERR  TEXT;
  V_DIED BOOLEAN;
BEGIN
  
  -- P_ERR cannot be NULL or EMPTY
  IF LENGTH(COALESCE(P_ERR, '')) = 0 THEN
    RAISE EXCEPTION 'P_ERR cannot be null or empty';
  END IF;
  
  -- P_QUERY cannot be NULL or EMPTY
  IF LENGTH(COALESCE(P_QUERY, '')) = 0 THEN
    RAISE EXCEPTION 'P_QUERY cannot be null or empty';
  END IF;

  BEGIN
    -- Execute the call
    V_DIED := TRUE;
    EXECUTE P_QUERY;
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_ERR = MESSAGE_TEXT;
  END;
  
  CASE
    -- Did an exception occur?
    WHEN NOT V_DIED
    THEN RAISE EXCEPTION 'Expected exception ''%'' did not occur', P_ERR;
  
    -- If an exception is expected, does it have the right text?
    WHEN NOT V_ERR = P_ERR
    THEN RAISE EXCEPTION 'The expected exception message ''%'' does not match the actual message ''%'' for ''%''', P_ERR, V_ERR, P_QUERY;
    
    ELSE NULL;
  END CASE;
  
  -- Success
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Test TEST(P_MSG, P_TEST)
DO $$
DECLARE
  V_DIED BOOLEAN;
  V_MSG  TEXT;
BEGIN
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST(NULL, NULL::BOOLEAN);
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
  
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('', NULL::BOOLEAN);
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
  
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('TEST', NULL::BOOLEAN);
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

-- Test TEST(P_ERR, P_QUERY)
DO $$
DECLARE
  V_DIED BOOLEAN;
  V_ERR  TEXT;
  V_MSG TEXT;
  V_RES  TEXT;
BEGIN
  -- P_ERR cannot be null
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST(NULL, NULL::TEXT);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'P_ERR cannot be null or empty' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG cannot be null or empty';
      END IF;
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_MSG is NULL';
  END IF;
  
  -- P_ERR cannot be empty
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('', NULL::TEXT);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'P_ERR cannot be null or empty' THEN
        RAISE EXCEPTION 'code.TEST must die with P_MSG cannot be null or empty';
      END IF;
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_MSG is empty';
  END IF;
  
  -- P_QUERY cannot be null
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('ERR', NULL::TEXT);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'P_QUERY cannot be null or empty' THEN
        RAISE EXCEPTION 'code.TEST must die with P_QUERY cannot be null or empty';
      END IF;
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_QUERY is NULL';
  END IF;
  
  -- P_QUERY cannot be empty
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('ERR', NULL::TEXT);
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'P_QUERY cannot be null or empty' THEN
        RAISE EXCEPTION 'code.TEST must die with P_QUERY cannot be null or empty';
      END IF;
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when P_QUERY is empty';
  END IF;
  
  -- Test error calling COALESCE(), where the error message provided IS correct
  BEGIN
    SELECT code.TEST('syntax error at or near ")"', 'SELECT COALESCE()') INTO V_RES;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      RAISE EXCEPTION 'code.TEST COALESCE() died when we provided correct error message: %', V_MSG;
  END;
  
  -- Test error calling COALESCE(), where the error message provided IS NOT correct
  BEGIN
    V_DIED := TRUE;
    SELECT code.TEST('wrong error message', 'SELECT COALESCE()') INTO V_RES;
    V_DIED := FALSE;
  EXCEPTION
    WHEN OTHERS THEN
      GET STACKED DIAGNOSTICS V_MSG = MESSAGE_TEXT;
      IF NOT V_MSG = 'The expected exception message ''wrong error message'' does not match the actual message ''syntax error at or near ")"'' for ''SELECT COALESCE()''' THEN
        RAISE EXCEPTION 'code.TEST COALESCE() with wrong error message did not return expected error message: %', V_MSG;
      END IF;
  END;
  IF NOT V_DIED THEN
    RAISE EXCEPTION 'code.TEST must die when COALESCE() fails and we provided wrong error message';
  END IF;
END;
$$ LANGUAGE plpgsql;

-- IIF: A polymorphic function some other vendors have that Postgres lacks
--   P_EXPR     : A boolean expression
--   P_TRUE_VAL : value to return if P_EXPR is true
--   P_FALSE_VAL: value to return if P_EXPR is false or null
--
-- Returns P_TRUE_VAL (which may be null) if P_EXPR is true, else P_FALSE_VAL (which may be null)
-- Raises an exception if P_TRUE_VAL and P_FALSE_VAL are both null
CREATE OR REPLACE FUNCTION code.IIF(P_EXPR BOOLEAN, P_TRUE_VAL ANYELEMENT, P_FALSE_VAL ANYELEMENT) RETURNS ANYELEMENT AS
$$
BEGIN 
  IF (P_TRUE_VAL IS NULL) AND (P_FALSE_VAL IS NULL) THEN
    RAISE EXCEPTION 'P_TRUE_VAL and P_FALSE_VAL cannot both be null';
  END IF;
  
  RETURN CASE WHEN P_EXPR THEN P_TRUE_VAL ELSE P_FALSE_VAL END;
END;
$$ LANGUAGE plpgsql IMMUTABLE LEAKPROOF PARALLEL SAFE;

-- Test IIF
SELECT DISTINCT *
  FROM (
    SELECT code.TEST('P_TRUE_VAL and P_FALSE_VAL cannot both be null', 'SELECT code.IIF(TRUE, NULL::TEXT, NULL)')
     UNION ALL
    SELECT code.TEST(format('code.IIF(%s, %s, %s) must return %s', expr, tval, fval, res), code.IIF(expr, tval, fval) IS NOT DISTINCT FROM res)
      FROM (VALUES
              (TRUE , NULL::TEXT, 'b' , NULL)
             ,(FALSE, NULL::TEXT, 'b' , 'b' )
             
             ,(TRUE , 'a'::TEXT , NULL, 'a' )
             ,(FALSE, 'a'::TEXT , NULL, NULL)
             
             ,(TRUE , 'a'::TEXT , 'b' , 'a' )
             ,(FALSE, 'a'::TEXT , 'b' , 'b' )
           ) AS t (expr, tval, fval, res)
  ) t;

-- NEMPTY_WS: a version of CONCAT_WS that treats empty strings like nulls, and coalesces consecutive empty/nulls
--   P_SEP : The separator string
--   P_STRS: The strings to place a separator between
--
-- Returns each non-null non-empty string in P_STRS, separated by P_SEP
-- Unlike CONCAT_WS, the nulls and empty strings are removed first, eliminating consecutive separators 
CREATE OR REPLACE FUNCTION code.NEMPTY_WS(P_SEP TEXT, P_STRS VARIADIC TEXT[]) RETURNS TEXT AS
$$
  SELECT STRING_AGG(strs, P_SEP)
    FROM (SELECT UNNEST(P_STRS) strs) t
   WHERE LENGTH(COALESCE(strs, '')) > 0
$$ LANGUAGE SQL IMMUTABLE LEAKPROOF PARALLEL SAFE;

-- Test NEMPTY_WS
SELECT DISTINCT code.TEST(msg, code.NEMPTY_WS('-', VARIADIC args) IS NOT DISTINCT FROM res) nempty_ws
  FROM (VALUES
          ('NEMPTY_WS must return NULL 1' , ARRAY[                                             ]::TEXT[], NULL     )
         ,('NEMPTY_WS must return NULL 2' , ARRAY[NULL                                         ]::TEXT[], NULL     )
         ,('NEMPTY_WS must return NULL 3' , ARRAY[NULL, NULL                                   ]::TEXT[], NULL     )
         ,('NEMPTY_WS must return a'      , ARRAY['a'                                          ]        , 'a'      )
         ,('NEMPTY_WS must return a'      , ARRAY[NULL, 'a'                                    ]        , 'a'      )
         ,('NEMPTY_WS must return a'      , ARRAY['a' , NULL                                   ]        , 'a'      )
         ,('NEMPTY_WS must return a'      , ARRAY[NULL, 'a' , NULL                             ]        , 'a'      )
         ,('NEMPTY_WS must return a'      , ARRAY[''  , 'a'                                    ]        , 'a'      )     
         ,('NEMPTY_WS must return a'      , ARRAY['a' , ''                                     ]        , 'a'      )
         ,('NEMPTY_WS must return a'      , ARRAY[''  , 'a' , ''                               ]        , 'a'      )
         ,('NEMPTY_WS must return a'      , ARRAY[NULL, 'a' , ''                               ]        , 'a'      )
         ,('NEMPTY_WS must return a'      , ARRAY[''  , 'a' , NULL                             ]        , 'a'      )
         ,('NEMPTY_WS must return a-b'    , ARRAY[NULL, 'a' , ''  , 'b'                        ]        , 'a-b'    )
         ,('NEMPTY_WS must return a-b-c'  , ARRAY[NULL, NULL, 'a' , '' , '', 'b', '', NULL, 'c']        , 'a-b-c'  )
         ,('NEMPTY_WS must return a-b-c-d', ARRAY['a' , 'b' , 'c' , 'd'                        ]        , 'a-b-c-d')
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
          ('TO_8601() must return NOW'                   , ARRAY[]::TIMESTAMP[]                              , TO_CHAR(NOW() AT TIME ZONE 'UTC'                   , 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'))
         ,('TO_8601(NULL) must return NOW'               , ARRAY[NULL]::TIMESTAMP[]                          , TO_CHAR(NOW() AT TIME ZONE 'UTC'                   , 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'))
         ,('TO_8601(NOW - 1 DAY) must return NOW - 1 DAY', ARRAY[NOW() AT TIME ZONE 'UTC' - INTERVAL '1 DAY'], TO_CHAR(NOW() AT TIME ZONE 'UTC' - INTERVAL '1 DAY', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'))
       ) AS t(msg, arg, res);

-- RELID_TO_ID converts a BIGINT to a base 62 string with a maximum of 11 chars
-- Maximum signed BIGINT value is 9_223_372_036_854_775_807 -> AzL8n0Y58m7
--                                                             12345678901
-- Raises an exception if P_RELID is NULL or < 1, since valid relids start at 1
CREATE OR REPLACE FUNCTION code.RELID_TO_ID(P_RELID BIGINT) RETURNS VARCHAR(11) AS
$$
DECLARE
  V_RELID BIGINT := P_RELID;
  V_DIGIT CHAR;
  V_ID VARCHAR(11) = '';
  V_RMDR INT;
BEGIN
  IF COALESCE(V_RELID, 0) < 1 THEN
    RAISE EXCEPTION 'P_RELID cannot be NULL or < 1';
  END IF;

  WHILE V_RELID > 0 LOOP
    V_RMDR = V_RELID % 62;
    CASE
      WHEN V_RMDR < 10      THEN V_DIGIT = CHR(ASCII('0') + V_RMDR          );
      WHEN V_RMDR < 10 + 26 THEN V_DIGIT = CHR(ASCII('A') + V_RMDR - 10     );
      ELSE                       V_DIGIT = CHR(ASCII('a') + V_RMDR - 10 - 26);
    END CASE;
    
    -- Add digits to the front of the string, modulus gives us the digits from least to most significant
    -- Eg for the relid 123, we get the digits 3,2,1
    V_ID    = V_DIGIT || V_ID;
    V_RELID = V_RELID /  62;
  END LOOP;
  
  RETURN V_ID;
END;
$$ LANGUAGE plpgsql IMMUTABLE LEAKPROOF PARALLEL SAFE;

--- Test RELID_TO_ID
SELECT DISTINCT * FROM (
  SELECT code.TEST('P_RELID cannot be NULL or < 1', q)
    FROM (VALUES
            ('SELECT code.RELID_TO_ID(NULL)')
           ,('SELECT code.RELID_TO_ID(0)'   )
           ,('SELECT code.RELID_TO_ID(-1)'  )
         ) AS t(q)
   UNION ALL
  SELECT code.TEST(format('RELID_TO_ID(%s) must return %s', r, i), code.RELID_TO_ID(r) = i)
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
-- Uses C collation for ASCII case-sensitive sorting regardless of database collation
CREATE OR REPLACE FUNCTION code.ID_TO_RELID(P_ID VARCHAR(11)) RETURNS BIGINT AS
$$
DECLARE
  --                                              12345678901
  C_LPAD_ID  CONSTANT CHAR(11) := LPAD(P_ID, 11, '00000000000') COLLATE "C";
  C_LPAD_MIN CONSTANT CHAR(11) :=                '00000000001'  COLLATE "C";
  C_LPAD_MAX CONSTANT CHAR(11) :=                'AzL8n0Y58m7'  COLLATE "C";
  
  C_0        CONSTANT INT := ASCII('0');
  C_9        CONSTANT INT := ASCII('9');
  C_CAP_A    CONSTANT INT := ASCII('A');
  C_CAP_Z    CONSTANT INT := ASCII('Z');
  C_LIT_A    CONSTANT INT := ASCII('a');
  C_LIT_Z    CONSTANT INT := ASCII('z');
  
  C_COUNT_DIGITS           CONSTANT INT := 10;
  C_COUNT_DIGITS_AND_LOWER CONSTANT INT := C_COUNT_DIGITS + 26; 
  
  V_ID          VARCHAR(11) := P_ID;
  V_DIGIT       CHAR;
  V_ASCII_DIGIT INT;
  V_RELID       BIGINT := 0;
BEGIN
  -- P_ID cannot be null or empty
  IF LENGTH(COALESCE(V_ID,'')) = 0 THEN
    RAISE EXCEPTION 'P_ID cannot be null or empty';
  END IF;
  
  -- P_ID must be >= '1' and <= 'AzL8n0Y58m7'
  IF (C_LPAD_ID < C_LPAD_MIN) OR (C_LPAD_ID > C_LPAD_MAX) THEN
    RAISE EXCEPTION 'P_ID must be in the range [1 .. AzL8n0Y58m7]';
  END IF;

  FOREACH V_DIGIT IN ARRAY REGEXP_SPLIT_TO_ARRAY(V_ID, '')
  LOOP
    -- Get the ASCII numeric value to guarantee an ASCII comparison 
    V_ASCII_DIGIT = ASCII(V_DIGIT);
    V_RELID = V_RELID * 62;
    
    CASE
      WHEN V_ASCII_DIGIT BETWEEN C_0     AND C_9     THEN V_RELID = V_RELID +                            (V_ASCII_DIGIT - C_0);
      WHEN V_ASCII_DIGIT BETWEEN C_CAP_A AND C_CAP_Z THEN V_RELID = V_RELID + C_COUNT_DIGITS +           (V_ASCII_DIGIT - C_CAP_A);
      WHEN V_ASCII_DIGIT BETWEEN C_LIT_A AND C_LIT_Z THEN V_RELID = V_RELID + C_COUNT_DIGITS_AND_LOWER + (V_ASCII_DIGIT - C_LIT_A);
      ELSE RAISE EXCEPTION 'P_ID digit ''%'' (ASCII 0x%) is invalid: only characters in the ranges of 0..9, A..Z, and a..z are valid', V_DIGIT, UPPER(TO_HEX(V_ASCII_DIGIT));
    END CASE;
  END LOOP;
  
  RETURN V_RELID;
END;
$$ LANGUAGE plpgsql IMMUTABLE LEAKPROOF PARALLEL SAFE;

--- Test ID_TO_RELID
SELECT DISTINCT * FROM (
  SELECT code.TEST(msg, q)
    FROM (VALUES
            ('P_ID cannot be null or empty', 'SELECT code.ID_TO_RELID(NULL)')
           ,('P_ID cannot be null or empty', 'SELECT code.ID_TO_RELID('''')')

           ,('P_ID must be in the range [1 .. AzL8n0Y58m7]', 'SELECT code.ID_TO_RELID(''0'')'          )
           ,('P_ID must be in the range [1 .. AzL8n0Y58m7]', 'SELECT code.ID_TO_RELID(''AzL8n0Y58m8'')')

           ,('P_ID digit ''-'' (ASCII 0x2D) is invalid: only characters in the ranges of 0..9, A..Z, and a..z are valid', 'SELECT code.ID_TO_RELID(''-1'')'  )
           ,('P_ID digit '':'' (ASCII 0x3A) is invalid: only characters in the ranges of 0..9, A..Z, and a..z are valid', 'SELECT code.ID_TO_RELID(''1:'')'  )
           ,('P_ID digit ''['' (ASCII 0x5B) is invalid: only characters in the ranges of 0..9, A..Z, and a..z are valid', 'SELECT code.ID_TO_RELID(''11['')' )
           ,('P_ID digit ''{'' (ASCII 0x7B) is invalid: only characters in the ranges of 0..9, A..Z, and a..z are valid', 'SELECT code.ID_TO_RELID(''111{'')')
         ) AS t(msg, q)
   UNION ALL
  SELECT code.TEST(format('ID_TO_RELID must return %s', r), code.ID_TO_RELID(i) = r)
    FROM (VALUES
            ('1'          , 1                        )
           ,('9'          , 9                        )
           ,('A'          , 10                       )
           ,('Z'          , 10 + 25                  )
           ,('a'          , 10 + 26                  )
           ,('z'          , 10 + 26 + 25             )
           ,('10'         , 10 + 26 + 26             )
           ,('Aukyoa'     , 10_000_000_000           )
           ,('AzL8n0Y58m7', 9_223_372_036_854_775_807)    
        ) AS t(i, r)
) t;
