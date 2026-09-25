FROM debian:bookworm-slim

RUN apt-get update \
	&& apt-get install -y --no-install-recommends mariadb-server \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/mariadb.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["mariadbd", "--user=mysql"]
