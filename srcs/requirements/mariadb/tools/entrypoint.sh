#!/bin/sh
set -e

# Directory
MARIADBD_DIR="/run/mysqld"
SOCKET="${MARIADBD_DIR}/mysqld.sock"
PID_FILE="${MARIADBD_DIR}/mysqld.pid"

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

# initialize a new database if necessary
if [ ! -d /var/lib/mysql/mysql ]; then

	mariadb-install-db \
		--user=mysql \
		--datadir=/var/lib/mysql

	mariadbd \
		--user=mysql \
		--datadir=/var/lib/mysql \
		--socket="${SOCKET}" \
		--pid-file="${PID_FILE}" \
		--skip-networking &
	
	i=0

	while ! mariadb-admin --no-defaults \
		--protocol=socket \
		--host=localhost \
		--socket="${SOCKET}" \
		-uroot ping --silent; do
		i=$((i+1))

		if [ "$i" -ge 30 ]; then

			echo "MariaDB failed to start"
			exit 1
		fi

		sleep 1
	done

	echo "Temporary MariaDB server is ready"

	mariadb --no-defaults \
		--protocol=socket \
		--host=localhost \
		--socket="${SOCKET}" \
		-uroot <<WTF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
	IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.*
	TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost'
	IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
WTF
	MYSQL_PWD="${MYSQL_ROOT_PASSWORD}" \
	mariadb-admin --no-defaults \
		--protocol=socket \
		--host=localhost \
		--socket="${SOCKET}" \
		-uroot \
		shutdown
fi

exec "$@"
