# User Documentation

## Services

This project provides a WordPress website running inside a virtual machine.

The application consists of three services:

- NGINX accepts HTTPS connections on port 443.
- WordPress and PHP-FPM serve the website and its administration panel.
- MariaDB stores WordPress users, posts, comments, and settings.

Only NGINX publishes a port to the host. WordPress and MariaDB communicate
through the internal Docker network.

## Start and Stop the Application

Run the following commands from the project root.

To build and start the application:

```sh
make
```

To stop and remove the application containers and network:

```sh
make down
```

The website and database data remain stored on the VM.

To start the application again:

```sh
make
```

## Access the Website

Website:

```text
https://kuyu.42.fr
```

Administration panel:

```text
https://kuyu.42.fr/wp-admin/
```

The computer running your browser must resolve `kuyu.42.fr` to an address
that reaches the VM's HTTPS port. Depending on the VM network configuration,
this may require a hosts-file entry and port forwarding.

NGINX uses a self-signed certificate. A browser security warning is expected.
Check that you are connecting to your own VM before accepting the certificate.

HTTP access on port 80 is not provided.

## Credentials

Account names and non-secret settings are configured in:

```text
srcs/.env
```

Passwords are stored locally in:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

These files must not be committed to Git or shared publicly.

With the current configuration:

- `kuyu` is the WordPress administrator.
- `author` is the ordinary WordPress user with the author role.

Use the corresponding password file when signing in.

To change a WordPress password, use the administration panel and update the
corresponding local secret file to keep the recorded password consistent.

Changing a secret file alone does not change a password already stored in
WordPress or MariaDB. Database password changes require coordinated updates
to the database account and its dependent configuration.

## Check Service Health

Display container status:

```sh
docker compose -f srcs/docker-compose.yml ps
```

All three services should be running. A running container alone does not
guarantee that the application is ready.

Inspect recent logs:

```sh
docker compose -f srcs/docker-compose.yml logs --tail=50
```

Check the website from inside the VM:

```sh
curl -k --resolve kuyu.42.fr:443:127.0.0.1 \
  --max-time 10 \
  -o /dev/null -sS \
  -w 'HTTP status: %{http_code}\n' \
  https://kuyu.42.fr/
```

An HTTP status of `200` indicates that the homepage responds successfully.
The `-k` option permits the self-signed certificate for this diagnostic.

Check that WordPress is installed:

```sh
docker compose -f srcs/docker-compose.yml exec -T wordpress \
  wp --allow-root --path=/var/www/html core is-installed
```

A successful command exits with status `0`.

## Persistent Data

Persistent data is stored on the VM under:

```text
/home/kuyu/data/wordpress
/home/kuyu/data/mariadb
```

Stopping or replacing containers does not normally remove these files.

Do not delete these directories unless you intend to erase the website or
database. Back up both directories before maintenance that could affect data.

## Troubleshooting

If the website is unavailable:

1. Check that the VM is running.
2. Check domain resolution and VM port forwarding.
3. Run the container status and log commands above.
4. Allow the initial WordPress installation to finish.

If login fails, verify the account name and its corresponding password.
Do not regenerate secrets as a password-reset method for an existing installation.

If the website returns `502 Bad Gateway`, inspect the WordPress logs and
confirm that PHP-FPM is running.

