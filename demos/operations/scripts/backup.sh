#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
mkdir -p backups
if [ -z "$(docker compose ps --status running -q grafana)" ]; then
    printf 'Grafana must be running before this cold-backup procedure.\n' >&2
    exit 1
fi
archive="grafana-$(date -u +%Y%m%dT%H%M%SZ).tar.gz"
# Stop SQLite writer before copying its database and accompanying files.
docker compose stop grafana
trap 'docker compose start grafana >/dev/null' EXIT
# Prometheus history and provisioning files are intentionally outside this archive.
docker compose --profile tools run --rm backup czf "/backup/$archive" -C /data .
printf 'Archive created: backups/%s\n' "$archive"
