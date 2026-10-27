#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p certs backups
if [ ! -f .env ]; then
    umask 077
    password=$(openssl rand -hex 24)
    printf 'GRAFANA_ADMIN_PASSWORD=%s\nGRAFANA_VOLUME=devops-demo-grafana-data\n' "$password" > .env
fi
if [ ! -f certs/server.crt ] || [ ! -f certs/server.key ]; then
    umask 077
    openssl req -x509 -nodes -newkey rsa:2048 -days 30 \
      -keyout certs/server.key -out certs/server.crt \
      -subj '/CN=localhost' -config scripts/tls.cnf
    chmod 600 certs/server.key
fi
printf 'Configuration ready. Start with: docker compose up -d\n'
