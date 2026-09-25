#!/bin/sh
set -e

# Check environment vairables
: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"

# prepare the runtime directory, the directory needed for the runtime
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

# initialize a new database if necessary
if [ ! -d /var/lib/mysql/mysql ]; then

	mariadb-install-db \
		--user=mysql \
		--datadir=/var/lib/mysql

	mariadbd \
		--user=mysql \
		--datadir=/var/lib/mysql \
		--socket=/run/mysql/mysqld.sock \
		--pid-file=/run/mysqld/mysqld.pid \
		--skip-networking &
	
	i=0

	while ! mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent; do
		i=$((i+1))

		if [ "$i" -ge 30 ]; then

			echo "MariaDB failed to start"
			exit 1
		fi

		sleep 1
	done

	echo "Temporary MariaDB server is ready"

	mariadb --socket=/run/mysqld/mysqld.sock <<WTF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%'
	IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.*
	TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost'
	IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
WTF
	mariadb-admin \
		--socket/run.mysqld/mysqld.sock \
		-uroot \
		-p"${MYSQL_ROOT_PASSWORD}" \
		shutdown
fi

exec "$@"
