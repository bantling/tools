-- Seed data for country and region tables
-- See https://www.iban.com/country-codes for 2 and 3 char country codes
-- See https://en.wikipedia.org/wiki/ISO_3166-2 for countries and region codes
--
-- When using ROW_NUMBER() to generate the order of the countries/regions, the ordering will match the order listed in
-- the VALUES clauses.
-- But when combining:
--   a left join onto the country/region tables to filter out already inserted values
--   a lateral join for calls to code.NEXT_BASE
-- The result is that the code.NEXT_BASE calls are in random order, causing generated relids to be in random order.
--
-- This is beneficial for seed algorithms that depend on countries, as they must be written to handle unordered relids.
-- In the case of regions, the random ordering is across all regions, regardless of country.
WITH COUNTRY_DATA AS (
  SELECT s.*
        ,ROW_NUMBER() OVER() AS ord
    FROM (VALUES
           ('United States'   , 'US'  , 'USA' , true       ,  true           , '^([0-9]{5}(-[0-9]{4})?)$'                       ,'\1'                )
          ,('Aruba'           , 'AW'  , 'ABW' , false      , false           , NULL                                             , NULL               )
          ,('Canada'          , 'CA'  , 'CAN' , true       ,  true           , '^([A-Za-z][0-9][A-Za-z]) ?([0-9][A-Za-z][0-9])$','\1 \2'             )
          ,('Christmas Island', 'CX'  , 'CXR' , false      ,  true           , '^6798$'                                         ,'6798'              )
         ) AS s(
            name              , code_2, code_3, has_regions, has_mailing_code, mailing_code_match                               , mailing_code_format
         )
)
-- SELECT * FROM COUNTRY_DATA;
,ROW_DATA AS (
  SELECT s.*
        ,t.*
        ,c.code_2 IS NOT NULL AS dup
    FROM COUNTRY_DATA s
    JOIN LATERAL(
           SELECT relid
             FROM code.NEXT_BASE('tables.country'::regclass::oid, s.name, s.name)
         ) t
      ON TRUE
    LEFT
    JOIN tables.country c
      ON c.code_2 = s.code_2
   WHERE 
)
-- SELECT * FROM ROW_DATA;
INSERT INTO tables.country(
   relid
  ,name
  ,code_2
  ,code_3
  ,has_regions
  ,has_mailing_code
  ,mailing_code_match
  ,mailing_code_format
  ,ord
)
SELECT relid
      ,name
      ,code_2
      ,code_3
      ,has_regions
      ,has_mailing_code
      ,mailing_code_match
      ,mailing_code_format
      ,ord
  FROM ROW_DATA
    ON CONFLICT(code_2)
    DO UPDATE SET ord = excluded.ord
        WHERE tables.country.ord != excluded.ord;

-- Regions
--
-- ANY NEW DATA ADDED AFTER INITIAL GO LIVE MUST BE ADDED IN A NEW SRC DIRECTORY
--
WITH CA_REGION_DATA AS (
  SELECT (SELECT relid FROM tables.country WHERE code_2 = 'CA') AS country_relid
        ,s.*
    FROM (VALUES
           ('Alberta'                  , 'AB')
          ,('British Columbia'         , 'BC')
          ,('Manitoba'                 , 'MB')
          ,('New Brunswick'            , 'NB')
          ,('Newfoundland and Labrador', 'NL')
          ,('Northwest Territories'    , 'NT')
          ,('Nova Scotia'              , 'NS')
          ,('Nunavut'                  , 'NU')
          ,('Ontario'                  , 'ON')
          ,('Prince Edward Island'     , 'PE')
          ,('Quebec'                   , 'QC')
          ,('Saskatchewan'             , 'SK')
          ,('Yukon'                    , 'YT')
        ) AS s(
            name                       , code
        )
)
, US_REGION_DATA AS (
  SELECT (SELECT relid FROM tables.country WHERE code_2 = 'US') country_relid
        ,s.*
    FROM (VALUES
           ('Alabama'                  , 'AL')
          ,('Alaska'                   , 'AK')
          ,('Arizona'                  , 'AZ')
          ,('Arkansaa'                 , 'AR')
          ,('California'               , 'CA')
          ,('Colorado'                 , 'CO')
          ,('Connecticut'              , 'CT')
          ,('Delaware'                 , 'DE')
          ,('District of Columbia'     , 'DC')
          ,('Florida'                  , 'FL')
          ,('Georgia'                  , 'GA')
          ,('Hawaii'                   , 'HI')
          ,('Idaho'                    , 'ID')
          ,('Illinois'                 , 'IL')
          ,('Indiana'                  , 'IN')
          ,('Iowa'                     , 'IA')
          ,('Kansas'                   , 'KS')
          ,('Kentucky'                 , 'KY')
          ,('Louisiana'                , 'LA')
          ,('Maine'                    , 'ME')
          ,('Maryland'                 , 'MD')
          ,('Massachusetts'            , 'MA')
          ,('Michigan'                 , 'MI')
          ,('Minnesota'                , 'MN')
          ,('Mississippi'              , 'MS')
          ,('Missouri'                 , 'MO')
          ,('Montana'                  , 'MT')
          ,('Nebraska'                 , 'NE')
          ,('Nevada'                   , 'NV')
          ,('New Hampshire'            , 'NH')
          ,('New Jersey'               , 'NJ')
          ,('New Mexico'               , 'NM')
          ,('New York'                 , 'NY')
          ,('North Dakota'             , 'ND')
          ,('Ohio'                     , 'OH')
          ,('Oklahoma'                 , 'OK')
          ,('Oregon'                   , 'OR')
          ,('Pennsylvania'             , 'PA')
          ,('Rhode Island'             , 'RI')
          ,('South Carolina'           , 'SC')
          ,('South Dakota'             , 'SD')
          ,('Tennessee'                , 'TN')
          ,('Texas'                    , 'TX')
          ,('Utah'                     , 'UT')
          ,('Vermont'                  , 'VT')
          ,('Virginia'                 , 'VA')
          ,('Washington'               , 'WA')
          ,('West Virginia'            , 'WV')
          ,('Wisconsin'                , 'WI')
          ,('Wyoming'                  , 'WY')
          ,('American Samoa'           , 'AS')
          ,('Guam'                     , 'GU')
          ,('Northern Mariana Islands' , 'MP')
          ,('Puerto Rico'              , 'PU')
          ,('Virgin Islands'           , 'VI')
         ) AS s(
           name                        , code
         )
)
-- SELECT * FROM US_REGION_DATA;
,REGION_DATA AS (
  SELECT *
        ,ROW_NUMBER() OVER(PARTITION BY s.country_relid) AS ord
    FROM (
    SELECT *
      FROM CA_REGION_DATA
     UNION ALL
    SELECT *
      FROM US_REGION_DATA
  ) s
)
-- SELECT * FROM REGION_DATA;
,ROW_DATA AS (
  SELECT s.*
        ,t.*
    FROM REGION_DATA s
    LEFT
    JOIN tables.region r
      ON r.country_relid = s.country_relid
     AND r.code = s.code
    JOIN LATERAL (
           SELECT *
             FROM code.NEXT_BASE('tables.region'::regclass::oid, s.name, s.name)
         ) t
      ON TRUE
   WHERE r.code IS NULL  
)
-- SELECT * FROM ROW_DATA
INSERT INTO tables.region(
  relid
 ,country_relid
 ,name
 ,code
 ,ord
)
SELECT relid
      ,country_relid
      ,name
      ,code
      ,ord
  FROM ROW_DATA;
