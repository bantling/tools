-- app_objects owns all database objects except functions and procedures
SELECT 'CREATE ROLE app_objects'
 WHERE NOT EXISTS (
	     SELECT 1
	       FROM pg_roles
	      WHERE rolname = 'app_objects'
 )
\gexec

-- app_exec owns all functions and procedures, and has a password for external access
SELECT 'CREATE ROLE app_exec PASSWORD ${APP_EXEC_PASS}'
 WHERE NOT EXISTS (
	     SELECT 1
	       FROM pg_roles
	      WHERE rolname = 'app_exec'
 )
\gexec
