#!/bin/sh
set -e

WP_PATH="/var/www/html"

: "${WP_URL:?WP_URL is required}"
: "${WP_TITLE:?WP_TITLE is required}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER is required}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL is required}"
: "${WP_USER:?WP_USER is required}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL is required}"

if ! wp --allow-root --path="$WP_PATH" core is-installed >/dev/null 2>&1; then
	: "${WP_ADMIN_PASSWORD_FILE:?WP_ADMIN_PASSWORD_FILE is required}"
	WP_ADMIN_PASSWORD="$(cat "$WP_ADMIN_PASSWORD_FILE")"

	wp --allow-root --path="$WP_PATH" core install \
		--url="$WP_URL" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL"
fi

if ! wp --allow-root --path="$WP_PATH" user get "$WP_USER" >/dev/null 2>&1; then
	: "${WP_USER_PASSWORD_FILE:?WP_USER_PASSWORD_FILE is required}"
	WP_USER_PASSWORD="$(cat "$WP_USER_PASSWORD_FILE")"

	wp --allow-root --path="$WP_PATH" user create "$WP_USER" "$WP_USER_EMAIL" \
		--role=author \
		--user_pass="$WP_USER_PASSWORD"
fi
