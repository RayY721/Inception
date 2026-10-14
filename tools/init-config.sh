#!/bin/sh
set -eu

# Newly created files are readable and writable only by their owner.
umask 077

# Resolve the project directory independently of the current directory.
PROJECT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
ENV_FILE="$PROJECT_DIR/srcs/.env"
ENV_TEMPLATE="$PROJECT_DIR/srcs/.env.example"
SECRETS_DIR="$PROJECT_DIR/secrets"

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: openssl is required." >&2
    exit 1
fi

if [ ! -f "$ENV_TEMPLATE" ]; then
    echo "Error: missing $ENV_TEMPLATE" >&2
    exit 1
fi

if [ -e "$ENV_FILE" ]; then
    echo "Keeping existing srcs/.env"
else
    cp "$ENV_TEMPLATE" "$ENV_FILE"
    echo "Created srcs/.env"
fi

mkdir -p "$SECRETS_DIR"

for name in db_password db_root_password wp_admin_password wp_user_password; do
    secret_file="$SECRETS_DIR/$name.txt"

    if [ -e "$secret_file" ]; then
        if [ ! -f "$secret_file" ] || [ ! -s "$secret_file" ]; then
            echo "Error: $secret_file must be a non-empty file." >&2
            exit 1
        fi
        echo "Keeping existing secrets/$name.txt"
    else
        # Generate before writing, so a generation failure leaves no empty file.
        password="$(openssl rand -hex 24)"
        printf '%s\n' "$password" > "$secret_file"
        echo "Created secrets/$name.txt"
    fi
done

echo "Configuration ready. Review srcs/.env before running make."
