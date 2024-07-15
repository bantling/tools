-- Country regions view, where regions is an array of all regions for the country, that is empty if there are no regions
CREATE OR REPLACE VIEW views.country_regions AS
SELECT jsonb_build_object(
          'id'                  ,c.id
         ,'name'                ,c.name
         ,'code2'               ,c.code_2
         ,'code3'               ,c.code_3
         ,'hasRegions'          ,c.has_regions
         ,'regions'             ,(SELECT jsonb_agg(
                                           jsonb_build_object(
                                              'id'  , r.id
                                             ,'name', r.name
                                             ,'code', r.code
                                           )
                                           ORDER
                                              BY r.name
                                         ) region
                                    FROM tables.region r
                                   WHERE r.country_relid = c.relid
                                 )
         ,'mailing_code_match'  ,c.mailing_code_match
         ,'mailing_code_format' ,c.mailing_code_format
       ) country_region
  FROM tables.country c
 ORDER
    BY c.name;
