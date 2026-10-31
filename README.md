*This project has been created as part of the 42 curriculum by kuyu.*

# Inception

## Description

Inception is a system administration project that uses Docker Compose to run a small web infrastructure inside a virtual machine. The required stack consists of NGINX, WordPress with PHP-FPM, and MariaDB, with persistent storage for the website and database.

NGINX is the only public entry point. It serves the site over HTTPS on port 443 using TLSv1.2 or TLSv1.3. WordPress and MariaDB communicate over a Docker network and are not exposed directly to visitors.

## Instructions

> Complete these steps to match the finished implementation before using this README as setup documentation.

1. Create a virtual machine and install Docker Engine, Docker Compose, and Make.
2. Clone this repository in the virtual machine.
3. Configure `kuyu.42.fr` to resolve to the virtual machine’s local IP address.
4. Create `srcs/.env` with the configuration variables required by `srcs/docker-compose.yml`. Set `DOMAIN_NAME=kuyu.42.fr`.
5. Create the required local secret files and keep them out of Git. Do not put passwords in Dockerfiles or committed configuration.
6. Ensure the persistent data directories are available under `/home/kuyu/data`.
7. From the repository root, build and start the stack:

   ```sh
   make
   ```

8. Open `https://kuyu.42.fr` to access the website. The WordPress administration panel is at `https://kuyu.42.fr/wp-admin`.

Use the commands documented in `USER_DOC.md` to stop the stack and check its status. `DEV_DOC.md` contains the full setup and maintenance instructions.

## Project description

The project uses one container per service, built from project Dockerfiles using a permitted Alpine or Debian base image. Docker Compose defines the services, their network, restart behavior, and two named volumes. The `Makefile` builds and starts the application.

```text
Visitor ── HTTPS :443 ──> NGINX ── PHP-FPM :9000 ──> WordPress
                              │                         │
                              │                         └── MariaDB :3306
                              │
                              └── Shared WordPress files volume

MariaDB ── Database volume
```

The WordPress files volume is shared by NGINX and WordPress. The database volume belongs to MariaDB. Both named volumes store their data under `/home/kuyu/data` on the virtual machine.

| Choice | Explanation |
| --- | --- |
| Virtual machines vs Docker | The virtual machine provides the required host environment. Docker runs the individual services as containers within it, sharing the host kernel instead of requiring a separate guest operating system for each service. |
| Secrets vs environment variables | Environment variables configure non-secret values such as the domain name. Confidential values belong in local, Git-ignored secret files; Docker Compose secrets can make those files available only to the services that need them. |
| Docker network vs host network | A Compose network lets services communicate by service name while keeping WordPress and MariaDB off the host’s public ports. Host networking is prohibited for this project. |
| Docker volumes vs bind mounts | Docker named volumes persist the database and website files across container replacement. Bind mounts directly expose host paths to containers and are not permitted for these two persistent stores. |

The repository’s `srcs/` directory contains the Compose configuration and service build files. The root `Makefile` is the entry point for building and running the stack. `USER_DOC.md` explains everyday use; `DEV_DOC.md` explains setup, configuration, container management, and data persistence.

## Resources

- [Docker Compose documentation](https://docs.docker.com/compose/) — defining and running the multi-container application.
- [Networking in Compose](https://docs.docker.com/compose/how-tos/networking/) — service discovery and container networking.
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/) — persistent container data.
- [Environment variables in Compose](https://docs.docker.com/compose/how-tos/environment-variables/) — configuration and variable interpolation.
- [Secrets in Docker Compose](https://docs.docker.com/compose/how-tos/use-secrets/) — supplying confidential values to services.

AI was used to draft this README, USER_DOC.md and DEV_DOC.md, including its structure, setup outline, and comparison of Docker concepts. The project owner must review the text and verify all setup steps against the completed implementation before submission.
