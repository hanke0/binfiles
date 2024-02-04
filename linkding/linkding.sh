#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
pwd

. ../lib.sh

entrypoint=$(
    cat <<'EOF1'
#!/usr/bin/env bash

set -e

cur=$(pwd)

if [ -z "${VIRTUAL_ENV}" ]; then
    VIRTUAL_ENV="$cur/venv"
fi

export PATH="${VIRTUAL_ENV}/bin:$PATH"
# Bootstrap script that gets executed in new Docker containers

LD_SERVER_PORT="${LD_SERVER_PORT:-9091}"

# Create data folder if it does not exist
mkdir -p data
# Create favicon folder if it does not exist
mkdir -p data/favicons

if [ ! -e "$cur/app/data" ]; then
    ln -sf "$cur/data" "$cur/app/data"
fi

cd app

sed -E \
    -e '/^uid ?= www-data/d' \
    -e '/^gid ?=/d' \
    -e '/stats ?=/d' \
    -e 's#pidfile ?=.+#pidfile = /var/run/linkding.pid#' \
    uwsgi.ini >uwsgi-run.ini

# Run database migration
python manage.py migrate
# Enable WAL journal mode for SQLite databases
python manage.py enable_wal
# Generate secret key file if it does not exist
python manage.py generate_secret_key
# Create initial superuser if defined in options / environment variables
python manage.py create_initial_superuser

# Start background task processor using supervisord, unless explicitly disabled
if [ "$LD_DISABLE_BACKGROUND_TASKS" != "True" ]; then
    supervisord --nodaemon -c supervisord.conf &
fi

# Start uwsgi server
exec uwsgi --http :$LD_SERVER_PORT uwsgi-run.ini
EOF1
)

make_docker_tarball \
    sissbruecker/linkding:1.24.0 \
    linkding 1.24.0 \
    "$entrypoint" \
    /etc/linkding /linkding/app
