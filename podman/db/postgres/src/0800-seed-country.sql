-- Seed data for counntry and region tables
-- See https://www.iban.com/country-codes for 2 and 3 char country codes
-- See https://en.wikipedia.org/wiki/ISO_3166-2 for countries and region codes
INSERT INTO tables.country(
   relid
  ,name
  ,code_2
  ,code_3
  ,has_regions
  ,has_mailing_code
  ,mailing_code_match
  ,mailing_code_format
) VALUES
  (
     code.NEXT_RELID()
    ,'Aruba'
    ,'AW'
    ,'ABW'
    ,false
    ,false
    ,NULL
    ,NULL
  ),
  (
     code.NEXT_RELID()
    ,'Canada'
    ,'CA'
    ,'CAN'
    ,true
    ,true
    ,'([A-Za-z][0-9][A-Za-z]) *([0-9][A-Za-z][0-9])'
    ,'\1 \2'
  ),
  (
     code.NEXT_RELID()
    ,'Christmas Island'
    ,'CX'
    ,'CXR'
    ,false
    ,true
    ,'6798'
    ,'6798'
  ),
  (
     code.NEXT_RELID()
    ,'United States'
    ,'US'
    ,'USA'
    ,true
    ,true
    ,'([0-9]{5}(?:-[0-9]{4})?)'
    ,'\1'
  );

-- Canadian provinces
INSERT INTO tables.region(
   relid
  ,country_relid
  ,name
  ,code
) VALUES
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Alberta'
    ,'AB'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'British Columbia'
    ,'BC'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Manitoba'
    ,'MB'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'New Brunswick'
    ,'NB'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Newfoundland and Labrador'
    ,'NL'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Northwest Territories'
    ,'NT'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Nova Scotia'
    ,'NS'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Nunavut'
    ,'NU'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Ontario'
    ,'ON'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Prince Edward Island'
    ,'PE'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Quebec'
    ,'QC'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Saskatchewan'
    ,'SK'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Yukon'
    ,'YT'
  );

-- American States
INSERT INTO tables.region(
    relid
   ,country_relid
   ,name
   ,code
) VALUES
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Alabama'
    ,'AL'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Alaska'
    ,'AK'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'American Samoa'
    ,'AS'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Arizona'
    ,'AZ'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Arkansaa'
    ,'AR'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'California'
    ,'CA'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Colorado'
    ,'CO'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Connecticut'
    ,'CT'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Delaware'
    ,'DE'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'District of Columbia'
    ,'DC'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Florida'
    ,'FL'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Georgia'
    ,'GA'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Guam'
    ,'GU'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Hawaii'
    ,'HI'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Idaho'
    ,'ID'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Illinois'
    ,'IL'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Indiana'
    ,'IN'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Iowa'
    ,'IA'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Kansas'
    ,'KS'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Kentucky'
    ,'KY'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Louisiana'
    ,'LA'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Maine'
    ,'ME'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Maryland'
    ,'MD'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Massachusetts'
    ,'MA'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Michigan'
    ,'MI'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Minnesota'
    ,'MN'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Mississippi'
    ,'MS'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Missouri'
    ,'MO'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Montana'
    ,'MT'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Nebraska'
    ,'NE'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Nevada'
    ,'NV'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'New Hampshire'
    ,'NH'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'New Jersey'
    ,'NJ'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'New Mexico'
    ,'NM'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'New York'
    ,'NY'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'North Dakota'
    ,'ND'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Northern Mariana Islands'
    ,'MP'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Ohio'
    ,'OH'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Oklahoma'
    ,'OK'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Oregon'
    ,'OR'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Pennsylvania'
    ,'PA'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Puerto Rico'
    ,'PU'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Rhode Island'
    ,'RI'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'South Carolina'
    ,'SC'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'South Dakota'
    ,'SD'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Tennessee'
    ,'TN'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Texas'
    ,'TX'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Utah'
    ,'UT'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Vermont'
    ,'VT'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Virgin Islands'
    ,'VI'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Virginia'
    ,'VA'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Washington'
    ,'WA'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'West Virginia'
    ,'WV'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Wisconsin'
    ,'WI'
  ),
  (
     code.NEXT_RELID()
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Wyoming'
    ,'WY'
  );
