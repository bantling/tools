DROP TABLE IF EXISTS product_node;
CREATE TABLE product_node(relid SERIAL, name TEXT NOT NULL, UNIQUE(name));
INSERT INTO product_node(name) VALUES('hairbrush'),('toothpaste'), ('vanity');

DROP TABLE IF EXISTS package_node;
CREATE TABLE package_node(relid SERIAL);
INSERT INTO package_node(relid) VALUES(1),(2),(3), (4);

DROP TABLE IF EXISTS package_node_contents;
CREATE TABLE package_node_contents(relid SERIAL, package_node_relid INT, product_node_relid INT);
INSERT INTO package_node_contents(package_node_relid, product_node_relid) VALUES(1, 1),(2, 2),(3, 1),(3, 2), (4, 3);

DROP TABLE IF EXISTS pallet_node;
CREATE TABLE pallet_node(relid SERIAL);
INSERT INTO pallet_node(relid) VALUES(1), (2);

DROP TABLE IF EXISTS pallet_node_contents;
CREATE TABLE pallet_node_contents(relid SERIAL, pallet_node_relid INT, package_node_relid INT, UNIQUE(pallet_node_relid, package_node_relid));
INSERT INTO pallet_node_contents(pallet_node_relid, package_node_relid) VALUES(1, 1),(1, 2),(1, 3), (2, 4);

DROP TABLE IF EXISTS shipment_node;
CREATE TABLE shipment_node(relid SERIAL);
INSERT INTO shipment_node(relid) VALUES(1), (2);

DROP TABLE IF EXISTS shipment_node_contents;
CREATE TABLE shipment_node_contents(relid SERIAL, shipment_node_relid INT, pallet_node_relid INT, UNIQUE(shipment_node_relid, pallet_node_relid));
INSERT INTO shipment_node_contents(shipment_node_relid, pallet_node_relid) VALUES(1, 1), (2, 2);

DROP TABLE IF EXISTS truck_node;
CREATE TABLE truck_node(relid SERIAL, truck_no TEXT NOT NULL, UNIQUE(truck_no));
INSERT INTO truck_node(truck_no) VALUES('DB123'), ('75469');

DROP TABLE IF EXISTS location_node;
CREATE TABLE location_node(relid SERIAL, location_no TEXT NOT NULL, location TEXT NOT NULL, UNIQUE(location_no));
INSERT INTO location_node(location_no, location) VALUES('PA-12', 'Storefront'),('OH-3', 'Warehouse');

DROP TABLE IF EXISTS delivery_node;
CREATE TABLE delivery_node(relid SERIAL, shipment_node_relid INT NOT NULL, truck_node_relid INT NOT NULL, location_node_relid INT NOT NULL, UNIQUE(shipment_node_relid, truck_node_relid, location_node_relid));
INSERT INTO delivery_node(shipment_node_relid, truck_node_relid, location_node_relid) VALUES(1, 1, 2), (2, 2, 1);

DROP TABLE IF EXISTS node;
CREATE TABLE node(relid SERIAL, tbl_oid OID, tbl_relid INT, UNIQUE (tbl_oid, tbl_relid));
INSERT INTO node(tbl_oid, tbl_relid) VALUES
  ('product_node'::regclass::oid, 1)  -- 1
 ,('product_node'::regclass::oid, 2)  -- 2
 ,('package_node'::regclass::oid, 1)  -- 3
 ,('package_node'::regclass::oid, 2)  -- 4
 ,('package_node'::regclass::oid, 3)  -- 5
 ,('pallet_node'::regclass::oid, 1)   -- 6
 ,('shipment_node'::regclass::oid, 1) -- 7
 ,('truck_node'::regclass::oid, 1)    -- 8
 ,('truck_node'::regclass::oid, 2)    -- 9
 ,('location_node'::regclass::oid, 1) -- 10
 ,('location_node'::regclass::oid, 2) -- 11
 ,('delivery_node'::regclass::oid, 1) -- 12

 ,('product_node'::regclass::oid, 3)  -- 13
 ,('package_node'::regclass::oid, 4)  -- 14
 ,('pallet_node'::regclass::oid, 2)   -- 15
 ,('shipment_node'::regclass::oid, 2) -- 16
 ,('delivery_node'::regclass::oid, 2) -- 17
 ;

DROP TABLE IF EXISTS edge;
CREATE TABLE edge(relid SERIAL, src INT, tgt INT, PRIMARY KEY (relid), UNIQUE (src, tgt));
INSERT INTO edge(src, tgt) VALUES
  -- product -> package
  (1, 3)
 ,(2, 4)
 ,(1, 5)
 ,(2, 5)
 -- package -> pallet
 ,(3, 6)
 ,(4, 6)
 ,(5, 6)
 -- pallet -> shipment
 ,(6, 7)
 -- shipment -> truck
 ,(7, 8)
 -- truck -> location
 ,(8, 11)
 -- shipment -> delivery
 ,(7, 12)
 -- truck -> delivery
 ,(8, 12)
 -- location -> delivery
 ,(11, 12)
 -- 1-8,11-12

 -- product -> package
 ,(13, 14)
 -- package -> pallet
 ,(14, 15)
 -- pallet -> shipment
 ,(15, 16)
 -- shipment -> truck
 ,(16, 9)
 -- truck -> location
 ,(9, 10)
 -- truck -> delivery
 ,(9, 17)
 -- location -> delivery
 ,(10, 17)
 -- 9-10,13-17
 ;

CREATE OR REPLACE FUNCTION graph(P_START INT) RETURNS TABLE(
  src       INT,
  tgt       INT,
  relname   TEXT,
  tbl_relid INT
) AS
$$
  WITH RECURSIVE find AS (
    SELECT e.src, e.tgt
      FROM edge e
     WHERE P_START IN (e.src, e.tgt)
     UNION
    SELECT e.src, e.tgt
      FROM find f
      JOIN edge e
        ON f.src IN (e.src, e.tgt)
        OR f.tgt IN (e.src, e.tgt)
  )
  SELECT f.src, f.tgt, pc.relname, n.tbl_relid
    FROM find f
    JOIN node n
      ON n.relid IN (f.src, f.tgt)
    JOIN pg_class pc
      ON pc.oid = n.tbl_oid
   ORDER BY 1, 2, 3, 4;
$$ LANGUAGE SQL;

-- First graph, starting in middle
SELECT * FROM graph(7);

-- Second graph, starting at beginning
SELECT * FROM graph(9);

\q
