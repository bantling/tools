\c mydb

SELECT 'CREATE SCHEMA myapp'
 WHERE NOT EXISTS (
   SELECT
     FROM information_schema.schemata
    WHERE schema_name = 'myapp'
 )
\gexec

\q
