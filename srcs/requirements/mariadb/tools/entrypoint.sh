#!/bin/sh
set -e

# Check environment vairables
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_password:?MYSQL_PASSWORD is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"

# prepare the runtime directory, the directory needed for the runtime
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# initialize a new database if necessary
if 
