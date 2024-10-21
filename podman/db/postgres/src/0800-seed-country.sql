-- Seed data for country and region tables
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
     (SELECT relid FROM code.NEXT_BASE('tables.country'::regclass::oid, 'Aruba', 'Aruba'))
    ,'Aruba'
    ,'AW'
    ,'ABW'
    ,false
    ,false
    ,NULL
    ,NULL
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.country'::regclass::oid, 'Canada', 'Canada'))
    ,'Canada'
    ,'CA'
    ,'CAN'
    ,true
    ,true
    ,'([A-Za-z][0-9][A-Za-z]) *([0-9][A-Za-z][0-9])'
    ,'\1 \2'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.country'::regclass::oid, 'Christmas Island', 'Christmas Island'))
    ,'Christmas Island'
    ,'CX'
    ,'CXR'
    ,false
    ,true
    ,'6798'
    ,'6798'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.country'::regclass::oid, 'United States', 'United States'))
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
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Alberta', 'Alberta'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Alberta'
    ,'AB'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'British Columbia', 'British Columbia'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'British Columbia'
    ,'BC'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Manitoba', 'Manitoba'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Manitoba'
    ,'MB'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'New Brunswick', 'New Brunswick'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'New Brunswick'
    ,'NB'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Newfoundland and Labrador', 'Newfoundland and Labrador'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Newfoundland and Labrador'
    ,'NL'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Northwest Territories', 'Northwest Territories'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Northwest Territories'
    ,'NT'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Nova Scotia', 'Nova Scotia'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Nova Scotia'
    ,'NS'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Nunavut', 'Nunavut'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Nunavut'
    ,'NU'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Ontario', 'Ontario'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Ontario'
    ,'ON'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Prince Edward Island', 'Prince Edward Island'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Prince Edward Island'
    ,'PE'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Quebec', 'Quebec'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Quebec'
    ,'QC'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Saskatchewan', 'Saskatchewan'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'Saskatchewan'
    ,'SK'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Yukon', 'Yukon'))
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
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Alabama', 'Alabama'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Alabama'
    ,'AL'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Alaska', 'Alaska'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Alaska'
    ,'AK'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'American Samoa', 'American Samoa'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'American Samoa'
    ,'AS'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Arizona', 'Arizona'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Arizona'
    ,'AZ'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Arkansaa', 'Arkansaa'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Arkansaa'
    ,'AR'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'California', 'California'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'California'
    ,'CA'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Colorado', 'Colorado'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Colorado'
    ,'CO'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Connecticut', 'Connecticut'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Connecticut'
    ,'CT'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Delaware', 'Delaware'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Delaware'
    ,'DE'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'District of Columbia', 'District of Columbia'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'District of Columbia'
    ,'DC'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Florida', 'Florida'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Florida'
    ,'FL'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Georgia', 'Georgia'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Georgia'
    ,'GA'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Guam', 'Guam'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Guam'
    ,'GU'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Hawaii', 'Hawaii'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Hawaii'
    ,'HI'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Idaho', 'Idaho'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Idaho'
    ,'ID'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Illinois', 'Illinois'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Illinois'
    ,'IL'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Indiana', 'Indiana'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Indiana'
    ,'IN'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Iowa', 'Iowa'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Iowa'
    ,'IA'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Kansas', 'Kansas'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Kansas'
    ,'KS'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Kentucky', 'Kentucky'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Kentucky'
    ,'KY'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Louisiana', 'Louisiana'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Louisiana'
    ,'LA'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Maine', 'Maine'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Maine'
    ,'ME'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Maryland', 'Maryland'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Maryland'
    ,'MD'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Massachusetts', 'Massachusetts'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Massachusetts'
    ,'MA'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Michigan', 'Michigan'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Michigan'
    ,'MI'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Minnesota', 'Minnesota'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Minnesota'
    ,'MN'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Mississippi', 'Mississippi'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Mississippi'
    ,'MS'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Missouri', 'Missouri'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Missouri'
    ,'MO'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Montana', 'Montana'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Montana'
    ,'MT'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Nebraska', 'Nebraska'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Nebraska'
    ,'NE'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Nevada', 'Nevada'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Nevada'
    ,'NV'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'New Hampshire', 'New Hampshire'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'New Hampshire'
    ,'NH'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'New Jersey', 'New Jersey'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'New Jersey'
    ,'NJ'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'New Mexico', 'New Mexico'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'New Mexico'
    ,'NM'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'New York', 'New York'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'New York'
    ,'NY'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'North Dakota', 'North Dakota'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'North Dakota'
    ,'ND'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Northern Mariana Islands', 'Northern Mariana Islands'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Northern Mariana Islands'
    ,'MP'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Ohio', 'Ohio'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Ohio'
    ,'OH'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Oklahoma', 'Oklahoma'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Oklahoma'
    ,'OK'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Oregon', 'Oregon'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Oregon'
    ,'OR'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Pennsylvania', 'Pennsylvania'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Pennsylvania'
    ,'PA'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Puerto Rico', 'Puerto Rico'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Puerto Rico'
    ,'PU'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Rhode Island', 'Rhode Island'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Rhode Island'
    ,'RI'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'South Carolina', 'South Carolina'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'South Carolina'
    ,'SC'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'South Dakota', 'South Dakota'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'South Dakota'
    ,'SD'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Tennessee', 'Tennessee'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Tennessee'
    ,'TN'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Texas', 'Texas'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Texas'
    ,'TX'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Utah', 'Utah'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Utah'
    ,'UT'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Vermont', 'Vermont'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Vermont'
    ,'VT'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Virgin Islands', 'Virgin Islands'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Virgin Islands'
    ,'VI'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Virginia', 'Virginia'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Virginia'
    ,'VA'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Washington', 'Washington'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Washington'
    ,'WA'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'West Virginia', 'West Virginia'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'West Virginia'
    ,'WV'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Wisconsin', 'Wisconsin'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Wisconsin'
    ,'WI'
  ),
  (
     (SELECT relid FROM code.NEXT_BASE('tables.region'::regclass::oid, 'Wyoming', 'Wyoming'))
    ,(SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'Wyoming'
    ,'WY'
  );
