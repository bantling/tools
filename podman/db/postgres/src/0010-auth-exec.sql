-- app_exec owns all functions and procedures, and has a password for external access
SELECT 'CREATE ROLE app_exec PASSWORD ''${APP_EXEC_PASS}'''
 WHERE NOT EXISTS (
	     SELECT 1
	       FROM pg_roles
	      WHERE rolname = 'app_exec'
 )
\gexec

-- Drop and recreate code schema, to guarantee that:
-- - It only has latest code
-- - No old overloads exist that are no longer needed
--
-- There MUST NOT exist any objects outside this schema that depend on objects in this schema.
-- Any such objects will also be dropped.
-- See https://www.postgresql.org/docs/current/sql-dropschema.html.
DROP SCHEMA IF EXISTS code CASCADE; 
CREATE SCHEMA IF NOT EXISTS code AUTHORIZATION app_exec;
