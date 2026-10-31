# Developer Documentation

## Prerequisites

Run the project inside a Linux virtual machine with:

- Git
- GNU Make
- Docker Engine
- The Docker Compose plugin
- OpenSSL

The user running the project must have permission to access the Docker daemon.
Access through the Docker group grants privileges equivalent to root.

Verify the required tools:

```sh
git --version
make --version
docker version
docker compose version
openssl version
```

The VM needs internet access to download base images, Debian packages,
WordPress, and WP-CLI during the build.

## Project Structure

```text
Makefile
README.md
USER_DOC.md
DEV_DOC.md
tools/
  init-config.sh
secrets/
srcs/
  .env
  .env.example
  docker-compose.yml
  requirements/
    nginx/
    wordpress/
    mariadb/
```

Each service has its own Dockerfile. Service configuration and startup
scripts are stored in the corresponding service directory.

The `.env` file and secret files are local configuration and must remain
excluded from Git.

## Initial Setup

Clone the submission repository and enter its root directory.

Create local configuration and secrets:

```sh
make init
```

This command runs `tools/init-config.sh`. The script:

- Copies `srcs/.env.example` to `srcs/.env` if it does not already exist.
- Generates four password files in `secrets/`.
- Preserves existing configuration and non-empty secret files.
- Uses restrictive permissions for newly created files.

Review `srcs/.env` before starting the application.

It defines the database name and user, database connection settings,
WordPress URL, website title, and WordPress account names and email addresses.

Ensure that:

- The website URL is `https://kuyu.42.fr`.
- The administrator username does not contain `admin` or `administrator`,
  regardless of capitalization.
- Account email addresses are appropriate for the installation.

The project uses `/home/kuyu/data` for persistent storage. If adapting it
for another login, update the paths in both the Makefile and Compose file,
and update the domain configuration where necessary.

## Domain and VM Networking

Configure `kuyu.42.fr` on the computer running the browser so that it resolves
to an address reaching the VM.

For bridged or host-only networking, this will normally be the VM's reachable
IP address. For NAT networking, configure HTTPS port forwarding and use the
address and port exposed by the hypervisor.

The website expects HTTPS on port 443.

If changing the domain, review:

- `WP_URL` in `srcs/.env`
- `server_name` in the NGINX configuration
- Certificate generation settings
- Browser-side name resolution

For an existing installation, changing `WP_URL` in `.env` alone does not
update the WordPress URL already stored in the database.

## Build and Launch

Build and start all services:

```sh
make
```

The Makefile creates the host data directories and runs:

```sh
docker compose -f srcs/docker-compose.yml up -d --build
```

Build images without launching containers:

```sh
make build
```

Validate Compose configuration without displaying resolved values:

```sh
docker compose -f srcs/docker-compose.yml config --quiet
```

The service images are built from the project's Dockerfiles using
`debian:bookworm-slim`.

Use explicit non-`latest` image tags, such as:

```text
nginx:1.0
wordpress:1.0
mariadb:1.0
```

## Service Architecture

NGINX is the public entry point and publishes port 443.

It reads WordPress files from the shared website volume and forwards PHP
requests to `wordpress:9000` using FastCGI.

The WordPress container runs PHP-FPM and connects to MariaDB using the
`mariadb` service name.

The three services communicate through the `inception` Docker bridge network.
MariaDB and PHP-FPM do not publish host ports.

The services use the `unless-stopped` restart policy. Their startup scripts
use `exec` to replace the shell with the main service process.

## Configuration and Secrets

Compose reads non-secret service settings from `srcs/.env`.

Passwords are provided through Compose secrets and mounted as files under
`/run/secrets/` inside the relevant containers.

| Local file | Used by |
|---|---|
| `secrets/db_password.txt` | MariaDB and WordPress |
| `secrets/db_root_password.txt` | MariaDB |
| `secrets/wp_admin_password.txt` | WordPress |
| `secrets/wp_user_password.txt` | WordPress |

On initial setup, the scripts create the database, database accounts,
WordPress installation, and WordPress accounts.

Existing database and WordPress credentials are not automatically changed
when a local secret file is edited.

For an initialized installation, coordinate password changes with the
existing accounts and WordPress database configuration.

Do not commit secrets or include their contents in logs, screenshots,
documentation, or issue reports.

## Manage Containers

Display service status:

```sh
docker compose -f srcs/docker-compose.yml ps
```

Follow logs:

```sh
docker compose -f srcs/docker-compose.yml logs -f
```

Open a shell in a service:

```sh
docker compose -f srcs/docker-compose.yml exec wordpress sh
```

Restart a service:

```sh
docker compose -f srcs/docker-compose.yml restart wordpress
```

A restart does not apply changes to the image or Compose configuration.
Run `make` after changing those files.

Stop and remove containers and the project network:

```sh
make down
```

`make clean` currently performs the same operation.

## Volumes and Persistence

The project defines two named volumes:

- `wordpress_data`, mounted at `/var/www/html`
- `mariadb_data`, mounted at `/var/lib/mysql`

They use the local volume driver with host-backed directories:

```text
/home/kuyu/data/wordpress
/home/kuyu/data/mariadb
```

The Compose configuration uses `driver_opts` with `o: bind` to back these
named volumes with the specified host paths.

List volumes:

```sh
docker volume ls
```

With the default project name derived from `srcs`, inspect them using:

```sh
docker volume inspect srcs_wordpress_data srcs_mariadb_data
```

If the Compose project name is overridden, use the actual names shown by
`docker volume ls`.

Inspect the network:

```sh
docker network inspect inception
```

WordPress files and database data survive container replacement because
they are stored outside the container filesystem.

## Cleanup Behavior

Remove containers, the network, and Compose volume definitions:

```sh
make fclean
```

The host data directories can remain after the named volumes are removed.
Therefore, `make fclean` is not a guaranteed factory reset.

The current `make re` runs `fclean` followed by `all`. It can reuse existing
host data and should not be treated as an empty-data initialization test.

To test first-time initialization, use a separate test VM or preserve the
existing data and prepare empty storage deliberately.

Back up both data directories before deleting or replacing persistent data.
Stop the stack before taking a filesystem-level backup of MariaDB.

## Verification

Check NGINX configuration:

```sh
docker compose -f srcs/docker-compose.yml exec -T nginx nginx -t
```

Check WordPress installation:

```sh
docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp --allow-root --path=/var/www/html core is-installed
```

List WordPress users and roles:

```sh
docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp --allow-root --path=/var/www/html user list \
  --fields=user_login,roles
```

List WordPress database tables:

```sh
docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp --allow-root --path=/var/www/html db tables
```

Open a MariaDB root session and enter the password from the local root
password file when prompted:

```sh
docker compose -f srcs/docker-compose.yml exec mariadb \
  mariadb --no-defaults --protocol=socket \
  --socket=/run/mysqld/mysqld.sock --host=localhost --user=root -p
```

Check HTTPS from inside the VM:

```sh
curl -k --resolve kuyu.42.fr:443:127.0.0.1 \
  --max-time 10 \
  -o /dev/null -sS \
  -w 'HTTP status: %{http_code}\n' \
  https://kuyu.42.fr/
```

Verify browser access, administrator login, ordinary-user comments, and page
editing separately.

For persistence testing, make an identifiable website change, stop and
restart the stack, and verify that it remains. Repeat the check after a VM
reboot. A successful container restart alone does not prove reboot persistence.

