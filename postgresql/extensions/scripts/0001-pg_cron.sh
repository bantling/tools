#!/bin/sh

# We need to append a line to the end of postgresql.conf to load the cron shared library
echo -e "shared_preload_libraries='pg_cron'\ncron.database_name = 'mydb'" >> ${PGDATA}/postgresql.conf

# Dump the postgres.conf file for debugging
cat ${PGDATA}/postgresql.conf

# Execute pg_ctl restart so that postgres reloads the updated config file
pg_ctl restart
