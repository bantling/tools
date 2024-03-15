\c mydb

-- postgis
SELECT postgis_full_version();

SELECT 'LINESTRING(0 0, 1 1, 2 1, 2 2)'::GEOMETRY;

-- pg_svg
select svgDoc(content => array[svgPolygon(pts => array[0.0, 0.0,  0.0, 50.0,  50.0, 50.0,  50.0, 0.0,  0.0, 0.0])]);

-- pg_cron
create table test(id serial);

select cron.schedule('test', '5 seconds', 'INSERT INTO test values(default)');

select * from test;

select * from cron.job_run_details order by start_time;

select cron.unschedule('test');

select * from test;

truncate table cron.job_run_details;

drop table test;

-- pg_http
SELECT * FROM http_get('http://httpbun.com/ip');

status |   content_type   |                                                                                           headers                                                                                           |           content
--------+------------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+------------------------------
   200 | application/json | {"(Content-Length,33)","(Content-Type,application/json)","(Date,\"Wed, 13 Mar 2024 23:58:10 GMT\")","(X-Powered-By,httpbun/5025308c3a9df224c10faae403ae888ad5c3ecc5)","(Connection,close)"} | {                           +
       |                  |                                                                                                                                                                                             |   "origin": "142.134.65.116"+
       |                  |                                                                                                                                                                                             | }                           +
       |                  |                                                                                                                                                                                             |
