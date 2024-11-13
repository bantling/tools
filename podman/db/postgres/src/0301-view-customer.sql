-- Join customer_person and their optional address
CREATE OR REPLACE VIEW views.customer_person_address AS
SELECT jsonb_build_object(
          'id'          ,code.RELID_TO_ID(cp.relid)
         ,'version'     ,cpb.version
         ,'created'     ,cpb.created
         ,'changed'     ,cpb.modified
         ,'first_name'  ,cp.first_name
         ,'middle_name' ,cp.middle_name
         ,'last_name'   ,cp.last_name
         ,'address'    ,(SELECT jsonb_strip_nulls(
                                  jsonb_build_object(
                                     'id'           ,code.RELID_TO_ID(a.relid)
                                    ,'version'      ,ab.version
                                    ,'created'      ,ab.created
                                    ,'changed'      ,ab.modified
                                    ,'city'         ,a.city
                                    ,'address'      ,a.address
                                    ,'country'      ,c.code_2
                                    ,'region'       ,r.code
                                    ,'mailing_code' ,a.mailing_code
                                  )
                                ) address
                            FROM tables.address a
                            JOIN tables.base ab
                              ON ab.relid = a.relid
                            JOIN tables.country c
                              ON c.relid = a.country_relid
                            LEFT
                            JOIN tables.region r
                              ON r.relid = a.region_relid
                           WHERE a.relid = cp.address_relid
                        )
       ) customer_person_address
  FROM tables.customer_person cp
  JOIN tables.base cpb
    ON cpb.relid = cp.relid
 ORDER
    BY  cp.last_name
       ,cp.first_name
       ,cp.middle_name;

-- Join customer_business and their address(es)
CREATE OR REPLACE VIEW views.customer_business_address AS
SELECT jsonb_build_object(
          'id'         ,code.RELID_TO_ID(cb.relid)
         ,'version'    ,cbb.version
         ,'created'    ,cbb.created
         ,'changed'    ,cbb.modified
         ,'name'       ,cb.name
         ,'addresses'  ,(SELECT jsonb_agg(
                                  jsonb_strip_nulls(
                                    jsonb_build_object(
                                       'id'          ,code.RELID_TO_ID(a.relid)
                                      ,'type'        ,t.name
                                      ,'version'     ,ab.version
                                      ,'created'     ,ab.created
                                      ,'changed'     ,ab.modified
                                      ,'city'        ,a.city
                                      ,'address_1'   ,a.address
                                      ,'address_2'   ,a.address_2
                                      ,'address_3'   ,a.address_3
                                      ,'country'     ,c.code_2
                                      ,'region'      ,r.code
                                      ,'mailing_code',a.mailing_code
                                    )
                                  )
                                  ORDER
                                     BY t.ord
                                ) address
                           FROM tables.address a
                           JOIN tables.base ab
                             ON ab.relid = a.relid
                           JOIN tables.country c
                             ON c.relid = a.country_relid
                           LEFT
                           JOIN tables.region r
                             ON r.relid = a.region_relid  
                           JOIN tables.address_type t
                             ON t.relid = a.address_type_relid
                           JOIN tables.customer_business_address_jt cba
                             ON cba.business_relid = cb.relid
                            AND cba.address_relid  = a.relid
                        )
       ) customer_business_address
  FROM tables.customer_business cb
  JOIN tables.base cbb
    ON cbb.relid = cb.relid
 ORDER
    BY cb.name;
