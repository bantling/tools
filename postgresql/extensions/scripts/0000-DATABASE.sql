SELECT 'CREATE DATABASE mydb encoding = ''UTF8'' locale = ''en_US.utf8'''
 WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'mydb')
\gexec
