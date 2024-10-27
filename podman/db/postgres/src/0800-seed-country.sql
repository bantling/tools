-- Seed data for country and region tables
-- See https://www.iban.com/country-codes for 2 and 3 char country codes
-- See https://en.wikipedia.org/wiki/ISO_3166-2 for countries and region codes
WITH COUNTRY_DATA AS (
  SELECT s.*
    FROM (VALUES
           ('Aruba'           , 'AW'  , 'ABW' , false      , false           , NULL                                             , NULL               )
          ,('Canada'          , 'CA'  , 'CAN' , true       ,  true           , '^([A-Za-z][0-9][A-Za-z]) ?([0-9][A-Za-z][0-9])$','\1 \2'             )
          ,('Christmas Island', 'CX'  , 'CXR' , false      ,  true           , '^6798$'                                         ,'6798'              )
          ,('United States'   , 'US'  , 'USA' , true       ,  true           , '^([0-9]{5}(-[0-9]{4})?)$'                       ,'\1'                )
         ) AS s(
            name              , code_2, code_3, has_regions, has_mailing_code, mailing_code_match                             , mailing_code_format
         )
    LEFT
    JOIN tables.country t 
      ON s.code_2 = t.code_2
   WHERE t.relid IS NULL
),
ROW_DATA AS (
  SELECT *
    FROM COUNTRY_DATA d
    JOIN LATERAL(
           SELECT relid
             FROM code.NEXT_BASE('tables.country'::regclass::oid, d.name, d.name) t
          ) ON TRUE
)
INSERT INTO tables.country(
   relid
  ,name
  ,code_2
  ,code_3
  ,has_regions
  ,has_mailing_code
  ,mailing_code_match
  ,mailing_code_format
)
SELECT relid
      ,name
      ,code_2
      ,code_3
      ,has_regions
      ,has_mailing_code
      ,mailing_code_match
      ,mailing_code_format
  FROM ROW_DATA;

-- Regions
--
-- ANY NEW DATA ADDED AFTER INITIAL GO LIVE MUST BE ADDED IN A NEW SRC DIRECTORY
--
WITH CA_REGION_DATA AS (
  SELECT (SELECT relid FROM tables.country WHERE code_2 = 'CA') country_relid
        ,s.*
        ,ROW_NUMBER() OVER() AS ord
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
    LEFT
    JOIN tables.region t
      ON t.country_relid = (SELECT relid FROM tables.country WHERE code_2 = 'CA')
      AND s.code = t.code
   WHERE t.relid IS NULL
)
, US_REGION_DATA AS (
  SELECT (SELECT relid FROM tables.country WHERE code_2 = 'US') country_relid
        ,s.*
        ,ROW_NUMBER() OVER() AS ord
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
    LEFT
    JOIN tables.region t
      ON t.country_relid = (SELECT relid FROM tables.country WHERE code_2 = 'US')
      AND s.code = t.code
   WHERE t.relid IS NULL
)
-- SELECT * FROM US_REGION_DATA;
,ROW_DATA AS (
  SELECT *
    FROM CA_REGION_DATA d
    JOIN LATERAL (
           SELECT *
             FROM code.NEXT_BASE('tables.region'::regclass::oid, d.name, d.name) t
          ) ON TRUE
   UNION ALL
  SELECT *
    FROM US_REGION_DATA d
    JOIN LATERAL (
           SELECT *
             FROM code.NEXT_BASE('tables.region'::regclass::oid, d.name, d.name) t
          ) ON TRUE
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
