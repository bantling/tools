-- Join country and optional regions such that:
-- If a country has no regions, then a single row is returned containing only the country and null region info
-- If a country has regions, then a row for each region is returned, with same country info and varying region info
CREATE OR REPLACE VIEW views.country_region AS
SELECT c.id          AS country_id
      ,c.name        AS country_name
      ,c.code_2      AS country_code_2
      ,c.code_3      AS country_code_3
      ,c.has_regions AS country_has_regions
      ,r.id          AS region_id
      ,r.name        AS region_name
      ,r.code        AS region_code
  FROM tables.country c
  LEFT JOIN tables.region r
    ON c.has_regions
   AND r.country_relid = c.relid;
