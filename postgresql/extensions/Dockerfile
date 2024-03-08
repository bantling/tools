FROM docker.io/library/postgres:latest

# Get list of packages, so we can install stuff
RUN apt-get update

# Install following packages:
# libcurl4-openssl-dev                           - curl dev libraries
# git                                            - clone repo
# build-essential                                - basic dev stuff like gcc and make
# postgresql-server-dev-<postgres major version> - postgres dev libraries
#
# We can get full version of postgres from "postgres --version" to get a value like this:
# postgres (PostgreSQL) 16.2 (Debian 16.2-1.pgdg120+2)
#
# Awk can grab the third field (16.2) and then using a dot separator grab the major number only (16)
RUN apt-get install -y \
  libcurl4-openssl-dev \
  git \
  build-essential \
  postgresql-server-dev-`postgres --version | awk '{print $3}' | awk -F. '{print $1}'`

# Compile and install extensions

# Compile and install the pgsql-http extension
RUN cd \;
    git clone https://github.com/pramsey/pgsql-http; \
    cd pgsql-http; \
    make; \
    make install; \
    cd \;
    rm -rf pgsql-http

# Compile the pg_cron extension
RUN cd \;
    git clone https://github.com/citusdata/pg_cron; \
    cd pg_cron; \
    make; \
    make install; \
    cd \;
    rm -rf pg_cron

# Get the pg_svg functions, and copy them to the /docker-entrypoint-initdb.d dir as file 0001 (0000 will create database)
RUN cd \;
    git clone https://github.com/dr-jts/pg_svg; \
    cp pg_svg/pg-svg-lib.sql /docker-entrypoint-initdb.d/0001-pg-svg-lib.sql; \
    cd \;
    rm -rf pg_svg

# Copy this programs postgres scripts to /docker-entrypoint-initdb.d
COPY scripts/* /docker-entrypoint-initdb.d
