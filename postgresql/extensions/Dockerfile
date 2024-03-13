FROM docker.io/library/postgres

# Install needed packages
# locales                               - set system locale
# build-essential                       - basic dev stuff like gcc and make
# git                                   - clone repos
# postgresql-postgis                    - postgres postgis support
# postgresql-<major version>-cron       - postgres cron extension
# postgresql-server-dev-<major version> - postgres dev libraries (needed to compile extensions)
# libcurl4-openssl-dev                  - curl dev libraries (needed for pgsql-http extension)
#
# We can get the major version of postgres by executing `postgres -V`,
# which returns a result like: postgres (PostgreSQL) 16.1 (Debian 16.1-1.pgdg120+1)
# We can use awk to print the third field, 16.1, then use awk again with dot separator to get first field, 16
RUN apt-get update && \
    apt-get install -y \
    locales \
    build-essential \
    git \
    postgresql-postgis \
    postgresql-`postgres -V | awk '{print $3}' | awk -F. '{print $1}'`-cron \
    postgresql-server-dev-`postgres -V | awk '{print $3}' | awk -F. '{print $1}'` \
    libcurl4-openssl-dev

# Set the locale correctly
RUN echo en_US.UTF-8 UTF-8 > /etc/locale.gen; \
    locale-gen

# Compile and install extensions
RUN mkdir /workdir

# Compile and install the pgsql-http extension
RUN cd /workdir; \
    git clone https://github.com/pramsey/pgsql-http; \
    cd pgsql-http; \
    make; \
    make install; \
    cd ..; \
    rm -rf pgsql-http

# Get the pg_svg functions, and copy the file to the /docker-entrypoint-initdb.d dir as file 0001 (0000 will create database).
# The script is simplistic, and just launches into loading functions into current database.
# Modify it to add a "\c mydb" line at the top, so functions are created in mydb, not postgres database.
# The version of echo on this system does not recognize the -e option for escapes, so use printf instead.
RUN cd /workdir; \
    git clone https://github.com/dr-jts/pg_svg; \
    printf '\c mydb\n' > /docker-entrypoint-initdb.d/0003-pg-svg-lib.sql; \
    cat pg_svg/pg-svg-lib.sql >> /docker-entrypoint-initdb.d/0003-pg-svg-lib.sql; \
    rm -rf pg_svg

# Cleanup
RUN rmdir /workdir

# Copy this programs postgres scripts to /docker-entrypoint-initdb.d
COPY scripts/* /docker-entrypoint-initdb.d
