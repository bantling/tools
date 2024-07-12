-- Join customer_person and their optional address
CREATE OR REPLACE VIEW views.customer_person_address AS
SELECT jsonb_build_object(
          'id'          ,c.id
         ,'version'     ,c.version
         ,'created'     ,c.created
         ,'changed'     ,c.changed
         ,'first_name'  ,c.first_name
         ,'middle_name' ,c.middle_name
         ,'last_name'   ,c.last_name
         ,'address'    ,(SELECT jsonb_build_object(
                                   'id'          ,a.id
                                  ,'version'     ,a.version
                                  ,'created'     ,a.created
                                  ,'changed'     ,a.changed
                                  ,'city'        ,a.city
                                  ,'address'     ,a.address
                                  ,'mailing_code',a.mailing_code
                                ) address
                            FROM tables.address a
                           WHERE a.relid = c.address_relid  
                        )
       ) customer_person_address
  FROM tables.customer_person c
 ORDER
    BY  c.last_name
       ,c.first_name
       ,c.middle_name;

-- Join customer_business and their address(es)
CREATE OR REPLACE VIEW views.customer_business_address AS
SELECT jsonb_build_object(
          'id'         ,c.id
         ,'version'    ,c.version
         ,'created'    ,c.created
         ,'changed'    ,c.changed
         ,'name'       ,c.name
         ,'addresses'  ,(SELECT jsonb_agg(
                                  jsonb_build_object(
                                     'id'          , a.id
                                    ,'type'        , t.name
                                    ,'version'     , a.version
                                    ,'created'     , a.created
                                    ,'changed'     , a.changed
                                    ,'city'        , a.city
                                    ,'address_1'   , a.address
                                    ,'address_2'   , a.address_2
                                    ,'address_3'   , a.address_3
                                    ,'mailing_code', a.mailing_code
                                  )
                                  ORDER
                                     BY t.ord
                                ) address
                           FROM tables.address a
                           JOIN tables.address_type t
                             ON t.relid = a.type_relid
                           JOIN tables.customer_business_address_jt cba
                             ON cba.business_relid = c.relid
                            AND cba.address_relid  = a.relid  
                        )
       ) customer_business_address
  FROM tables.customer_business c
 ORDER
    BY c.name;
