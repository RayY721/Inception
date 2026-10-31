#!/bin/sh
set -e

# Directory
MARIADBD_DIR="/run/mysqld"
INIT_PENDING=/var/lib/mysql/.init-pending

if [ -n "${MYSQL_PASSWORD_FILE:-}" ]; then
	MYSQL_PASSWORD="$(cat "${MYSQL_PASSWORD_FILE}")"
	export MYSQL_PASSWORD
fi

if [ -n "${MYSQL_ROOT_PASSWORD_FILE:-}" ]; then
	MYSQL_ROOT_PASSWORD="$(cat "${MYSQL_ROOT_PASSWORD_FILE}")"
	export MYSQL_ROOT_PASSWORD
fi

# Check environment vairables
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"

# prepare the runtime directory, the directory needed for the runtime
mkdir -p "${MARIADBD_DIR}"
chown mysql:mysql "${MARIADBD_DIR}"

if [ -f "$INIT_PENDING" ]; then
    echo "Error: previous database initialization failed." >&2
    echo "Check the logs and recover the data directory before restarting." >&2
    exit 1
fi

# initialize a new database if necessary
if [ ! -d /var/lib/mysql/mysql ]; then
	touch "$INIT_PENDING"

	mariadb-install-db \
		--user=mysql \
		--datadir=/var/lib/mysql \
		--skip-test-db

	mariadbd \
		--user=mysql \
		--datadir=/var/lib/mysql \
		--bootstrap <<SQL
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
SQL

	rm -f "$INIT_PENDING"
fi

exec "$@"
