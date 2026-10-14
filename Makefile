COMPOSE = docker compose -f srcs/docker-compose.yml

DATA_DIR = /home/kuyu/data
WP_DATA = $(DATA_DIR)/wordpress
DB_DATA = $(DATA_DIR)/mariadb

all: up

up:
	mkdir -p $(WP_DATA) $(DB_DATA)
	$(COMPOSE) up -d --build

build:
	$(COMPOSE) build

down:
	$(COMPOSE) down

clean: down

fclean: down
	$(COMPOSE) down -v

re: fclean all

init:
	sh tools/init-config.sh

up-mariadb:
	mkdir -p $(WP_DATA) $(DB_DATA)
	$(COMPOSE) up mariadb

.PHONY: all up build down clean fclean re init up-mariadb
