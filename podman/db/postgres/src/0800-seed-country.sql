-- Seed data for counntry and region tables
-- See https://www.iban.com/country-codes for 2 and 3 char country codes
-- See https://en.wikipedia.org/wiki/ISO_3166-2 for countries and region codes
INSERT INTO tables.country(
   id
  ,name
  ,code_2
  ,code_3
  ,has_regions
  ,mailing_code_match
  ,mailing_code_format
) VALUES
  (
     'BE5A978E-AFF7-4EDE-A994-03C07366F9F6'::UUID
    ,'Aruba'
    ,'AW'
    ,'ABW'
    ,false
    ,NULL
    ,NULL
  ),
  (
     'D273DF38-2798-4B72-AC83-7FE145D5B8A7'::UUID
    ,'Canada'
    ,'CA'
    ,'CAN'
    ,true
    ,'([A-Za-z][0-9][A-Za-z]) *([0-9][A-Za-z][0-9])'
    ,'\1 \2'
  ),
  (
     '07A5A579-895D-4965-9436-2B603D2FF43A'::UUID
    ,'Christmas Island'
    ,'CX'
    ,'CXR'
    ,false
    ,'6798'
    ,'6798'
  ),
  (
     '4EE216CA-0032-4951-AC9D-5547AFCC8707'::UUID
    ,'United States'
    ,'US'
    ,'USA'
    ,true
    ,'([0-9]{5}(?:-[0-9]{4})?)'
    ,'\1'
  );

-- Canadian provinces
INSERT INTO tables.region(
    country_relid
   ,id
   ,name
   ,code
) VALUES
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'EB15DE4C-DFC1-4219-8256-39784F48F76A'
    ,'Alberta'
    ,'AB'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'8AA9686B-21BF-44D5-9D31-F2D2DFD1D22F'
    ,'British Columbia'
    ,'BC'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'56597C19-2C8D-44F6-99CF-4A1CC32D431A'
    ,'Manitoba'
    ,'MB'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'5FA91711-668E-42D1-B0AD-2EE5D83CE2CF'
    ,'New Brunswick'
    ,'NB'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'A5BD8CA7-C7EC-4058-8092-31EC6F0FD3FC'
    ,'Newfoundland and Labrador'
    ,'NL'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'7068D3A7-EA31-43A5-94D9-37039A1A2410'
    ,'Northwest Territories'
    ,'NT'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'DB1CD282-88EB-4193-B499-48125E23D24A'
    ,'Nova Scotia'
    ,'NS'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'7773D3A3-746E-4702-8BA0-702AF2D486E2'
    ,'Nunavut'
    ,'NU'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'C0F79E44-F6AF-4DE8-9CF6-6F205F3EF753'
    ,'Ontario'
    ,'ON'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'2255C75A-65A3-43D2-8D2B-E630E54B4D50'
    ,'Prince Edward Island'
    ,'PE'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'A95F239F-1BA8-4BEE-A786-A6CC98EB0F40'
    ,'Quebec'
    ,'QC'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'CCC98EBB-057C-4C8A-BED3-DD4E0D0014E3'
    ,'Saskatchewan'
    ,'SK'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'CA')
    ,'B34DFA61-6CDB-4083-9805-A4B1FF351ED2'
    ,'Yukon'
    ,'YT'
  );

-- American States
INSERT INTO tables.region(
    country_relid
   ,id
   ,name
   ,code
) VALUES
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'D031845D-226E-422E-B89E-FE96119B4B82'
    ,'Alabama'
    ,'AL'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'C8119372-48F1-4F0B-BC3B-761F3185D33F'
    ,'Alaska'
    ,'AK'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'7E5EF494-CD8A-48FD-8700-737FFDCABA8D'
    ,'American Samoa'
    ,'AS'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'AE0A670D-B31B-4FF4-9843-EDED50F93154'
    ,'Arizona'
    ,'AZ'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'788EAC9F-678C-4DE3-B1DD-FBC992123F23'
    ,'Arkansaa'
    ,'AR'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'F42393A4-8081-4D81-830D-891C9BFF1B83'
    ,'California'
    ,'CA'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'A3456544-3202-4AE5-9ECC-D061D0C8D399'
    ,'Colorado'
    ,'CO'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'55A91B03-E3B0-4CC6-A110-BB5D1B281B2E'
    ,'Connecticut'
    ,'CT'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'51D7778E-C30E-414E-83AB-67FE98437C30'
    ,'Delaware'
    ,'DE'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'DB93328E-795C-42EC-9CA2-79731964184C'
    ,'District of Columbia'
    ,'DC'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'21C51A5D-AAE3-4F3A-BBCB-17851BC87C34'
    ,'Florida'
    ,'FL'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'BB757A08-F7D5-4289-8EF2-BAB040AF601C'
    ,'Georgia'
    ,'GA'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'C35920DF-8AFD-4947-88C3-E8BF5E74F19C'
    ,'Guam'
    ,'GU'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'AE2AC99A-A5FA-49B0-AE1B-9FF3EED67D1C'
    ,'Hawaii'
    ,'HI'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'97191BC7-88E7-40E3-88FB-98374E8FA631'
    ,'Idaho'
    ,'ID'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'BFF249A8-11FA-471B-89E3-A652C3AADCC6'
    ,'Illinois'
    ,'IL'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'7117726A-AE84-47C7-8AFA-05B3F6CFED73'
    ,'Indiana'
    ,'IN'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'ABF9C329-BEAA-45EE-A504-B97932CEC5A1'
    ,'Iowa'
    ,'IA'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'5A2AE488-8F56-4145-8ED9-E1D9BFB1766B'
    ,'Kansas'
    ,'KS'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'A4F02E58-A5E6-40D5-BC40-74E19D10BA00'
    ,'Kentucky'
    ,'KY'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'275D7CEF-E6BE-414E-99CB-F335D00B8E48'
    ,'Louisiana'
    ,'LA'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'2A7D552F-7979-40BD-8D78-2A23367F251A'
    ,'Maine'
    ,'ME'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'B1820C93-48B1-4C8F-9D81-82175F7B5A6B'
    ,'Maryland'
    ,'MD'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'6B04BE21-BD15-43FA-A399-79C95BF62FC1'
    ,'Massachusetts'
    ,'MA'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'6BE8A7DB-93B8-4C5C-ABA1-94716F00C8F0'
    ,'Michigan'
    ,'MI'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'9DEA2F63-1556-4566-8B21-814C7C30C621'
    ,'Minnesota'
    ,'MN'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'AB07E792-7A54-424F-9DEB-0FA53C6039ED'
    ,'Mississippi'
    ,'MS'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'9C9653CA-C5A6-490B-B76D-5E107912705B'
    ,'Missouri'
    ,'MO'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'C0A0D3D9-AEAD-4B82-B345-CE35284381FA'
    ,'Montana'
    ,'MT'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'A9F833AB-69FB-45AC-B489-5EC926048AD4'
    ,'Nebraska'
    ,'NE'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'2380A0A5-56D8-462E-96A4-4C260218ED14'
    ,'Nevada'
    ,'NV'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'697F5CA8-A6D3-41F1-8239-89D4BC0940AE'
    ,'New Hampshire'
    ,'NH'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'4E16C25F-318A-4473-9644-24A5B40707D8'
    ,'New Jersey'
    ,'NJ'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'C2A4F815-9E90-456F-9DFD-9A9B4672FE2C'
    ,'New Mexico'
    ,'NM'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'9D8A57BF-AFB9-4766-9CE2-1936F633B210'
    ,'New York'
    ,'NY'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'8977E6DD-338C-456D-9D36-CA0F898D2B8E'
    ,'North Dakota'
    ,'ND'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'CC967C58-B686-491C-89B3-ED289E1C2363'
    ,'Northern Mariana Islands'
    ,'MP'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'CFF60CE1-A089-46BA-BF8B-DEE94F435700'
    ,'Ohio'
    ,'OH'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'C9FAA67A-4966-40F2-BAA5-902072E8B06B'
    ,'Oklahoma'
    ,'OK'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'18FF0A60-0563-4A28-B773-A39FC682478D'
    ,'Oregon'
    ,'OR'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'623AC3A3-A2D5-46B2-AC96-31BF460AEAE7'
    ,'Pennsylvania'
    ,'PA'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'A31DD132-6A59-42A0-BC42-FBDE655E4B00'
    ,'Puerto Rico'
    ,'PU'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'4146EED0-A7EA-4D01-85B1-8D9AD7EBB7DC'
    ,'Rhode Island'
    ,'RI'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'F9E7E310-6526-42EC-94B1-73A50ADD1FEC'
    ,'South Carolina'
    ,'SC'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'9E9ECDB6-3CD9-4CFD-A815-0284B3E523C3'
    ,'South Dakota'
    ,'SD'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'8355EF0C-C369-4ABB-ADA7-635E2FC89DF3'
    ,'Tennessee'
    ,'TN'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'39E8D7A4-365F-42D3-AC3D-2EA00C9DE817'
    ,'Texas'
    ,'TX'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'5FC06317-5C34-4BF9-A357-E9F756D8884E'
    ,'Utah'
    ,'UT'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'EF1078BD-9F4E-46BC-99E7-B7AFB7BDF724'
    ,'Vermont'
    ,'VT'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'1509F9BB-25B8-48CF-B704-DAAECFB145D9'
    ,'Virgin Islands'
    ,'VI'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'CFFA1A85-1382-4BB6-BDA4-4AC46286E952'
    ,'Virginia'
    ,'VA'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'1040E69F-4041-4718-BEF3-F7472B4F74D9'
    ,'Washington'
    ,'WA'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'6B2EB1CD-C527-4C01-88DB-2A562C4CEE16'
    ,'West Virginia'
    ,'WV'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'A479817A-6BB0-4240-B3C4-8DB36BA72BDE'
    ,'Wisconsin'
    ,'WI'
  ),
  (
     (SELECT relid FROM tables.country WHERE code_2 = 'US')
    ,'06B585D4-7220-4E9E-BF41-24237B92586C'
    ,'Wyoming'
    ,'WY'
  );
