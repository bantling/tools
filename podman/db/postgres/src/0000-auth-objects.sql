-- app_objects owns all database objects except functions and procedures
SELECT 'CREATE ROLE app_objects'
 WHERE NOT EXISTS (
	     SELECT 1
	       FROM pg_roles
	      WHERE rolname = 'app_objects'
 )
\gexec

-- Create tables schema
CREATE SCHEMA IF NOT EXISTS tables AUTHORIZATION app_objects;

-- Create views schema
CREATE SCHEMA IF NOT EXISTS views AUTHORIZATION app_objects;
