FROM debian:bookworm-slim

RUN apt-get update \
	&& apt-get install -y --no-install-recommends nginx \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/nginx.conf /etc/nginx/nginx.conf

CMD ["nginx", "-g", "daemon off;"]
