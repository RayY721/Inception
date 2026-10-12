#!/bin/sh
set -e

WP_PATH="/var/www/html"
WP_SOURCE="/usr/src/wordpress"
DB_HOST="${MYSQL_HOST:-mariadb}"
DB_PORT="${MYSQL_PORT:-3306}"

if [ -n "${MYSQL_PASSWORD_FILE:-}" ]; then
	MYSQL_PASSWORD="$(cat "$MYSQL_PASSWORD_FILE")"
	export MYSQL_PASSWORD
fi

: "${MYSQL_DATABASE:?MYSQL_DATABASE is required}"
: "${MYSQL_USER:?MYSQL_USER is required}"
: "${MYSQL_PASSWORD:?MYSQL_PASSWORD is required}"

mkdir -p /run/php "$WP_PATH"

until mariadb \
	--host="$DB_HOST" \
	--port="$DB_PORT" \
	--user="$MYSQL_USER" \
	--password="$MYSQL_PASSWORD" \
	"$MYSQL_DATABASE" \
	--execute="SELECT 1" >/dev/null 2>&1; do
	echo "Waiting for MariaDB..."
	sleep 2
done

if [ ! -f "$WP_PATH/wp-config.php" ]; then
	cp -a "$WP_SOURCE"/. "$WP_PATH"/
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
	cat > "$WP_PATH/wp-config.php" <<EOF
<?php
define( 'DB_NAME', '$MYSQL_DATABASE' );
define( 'DB_USER', '$MYSQL_USER' );
define( 'DB_PASSWORD', '$MYSQL_PASSWORD' );
define( 'DB_HOST', '$DB_HOST:$DB_PORT' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF
fi

/usr/local/bin/install-wordpress.sh

chown -R www-data:www-data "$WP_PATH"

exec "$@"
