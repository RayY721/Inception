FROM debian:bookworm-slim

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		php-fpm \
		php-mysql \
		php-cli \
		mariadb-client \
		curl \
		ca-certificates \
		tar \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /run/php /var/www/html /usr/src \
	&& curl -fsSL https://wordpress.org/latest.tar.gz -o /tmp/wordpress.tar.gz \
	&& tar -xzf /tmp/wordpress.tar.gz -C /usr/src \
	&& rm /tmp/wordpress.tar.gz \
	&& sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php/8.2/fpm/pool.d/www.conf \
	&& curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
	&& chmod +x /usr/local/bin/wp

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY tools/install-wordpress.sh /usr/local/bin/install-wordpress.sh

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/install-wordpress.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["php-fpm8.2", "-F"]
