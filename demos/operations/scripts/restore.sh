#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
if [ "$#" -ne 2 ]; then
    printf 'Usage: %s grafana-TIMESTAMP.tar.gz NEW_VOLUME_NAME\n' "$0" >&2
    exit 1
fi
archive=$1
volume=$2
case "$archive" in *[!a-zA-Z0-9._-]*|''|.*) echo 'Invalid archive name' >&2; exit 1;; esac
case "$volume" in *[!a-zA-Z0-9_.-]*|''|[!a-zA-Z0-9]*) echo 'Invalid volume name' >&2; exit 1;; esac
[ -f "backups/$archive" ] || { echo 'Archive not found' >&2; exit 1; }
if docker volume inspect "$volume" >/dev/null 2>&1; then
    echo 'Refusing to overwrite an existing volume. Choose a new volume name.' >&2
    exit 1
fi
# Only restore archives created by this demo; do not use untrusted archives.
docker volume create "$volume" >/dev/null
docker run --rm --user 0:0 --mount "type=volume,src=$volume,dst=/data" \
  --mount "type=bind,src=$PWD/backups,dst=/backup,readonly" \
  alpine:3.22.1 tar xzf "/backup/$archive" -C /data
printf 'Restored to volume: %s\n' "$volume"
printf 'Switch with: GRAFANA_VOLUME=%s docker compose up -d --force-recreate grafana\n' "$volume"
printf 'Rollback with: docker compose up -d --force-recreate grafana\n'
