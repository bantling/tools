-- Seed data for country and region tables
-- See https://www.iban.com/country-codes for 2 and 3 char country codes
-- See https://en.wikipedia.org/wiki/ISO_3166-2 for countries and region codes
WITH COUNTRY_DATA AS (
  SELECT s.*
        ,ROW_NUMBER() OVER() AS ord
    FROM (VALUES
           ('Aruba'           , 'AW'  , 'ABW' , false      , false           , NULL                                             , NULL               )
          ,('Canada'          , 'CA'  , 'CAN' , true       ,  true           , '^([A-Za-z][0-9][A-Za-z]) ?([0-9][A-Za-z][0-9])$','\1 \2'             )
          ,('Christmas Island', 'CX'  , 'CXR' , false      ,  true           , '^6798$'                                         ,'6798'              )
          ,('United States'   , 'US'  , 'USA' , true       ,  true           , '^([0-9]{5}(-[0-9]{4})?)$'                       ,'\1'                )
         ) AS s(
            name              , code_2, code_3, has_regions, has_mailing_code, mailing_code_match                               , mailing_code_format
         )
)
-- SELECT * FROM COUNTRY_DATA;
INSERT INTO tables.country(
   description
  ,terms
  ,name
  ,code_2
  ,code_3
  ,has_regions
  ,has_mailing_code
  ,mailing_code_match
  ,mailing_code_format
  ,ord
)
SELECT c.name                           AS description
      ,TO_TSVECTOR('english', c.name || ' ' || c.code_2 || ' ' || c.code_3) AS terms
      ,c.*
  FROM COUNTRY_DATA c
    ON CONFLICT(name) DO
UPDATE
   SET                ord  = excluded.ord
 WHERE tables.country.ord != excluded.ord;

-- Regions
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
-- SELECT * FROM CA_REGION_DATA;
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
          ,('North Carolina'           , 'NC')
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
INSERT INTO tables.region(
  description
 ,terms
 ,country_relid
 ,name
 ,code
 ,ord
)
SELECT r.name as description
      ,TO_TSVECTOR('english', r.name || ' ' || r.code) AS terms
      ,r.*
  FROM REGION_DATA r
    ON CONFLICT(name, country_relid) DO
UPDATE
   SET               ord  = excluded.ord
 WHERE tables.region.ord != excluded.ord;
