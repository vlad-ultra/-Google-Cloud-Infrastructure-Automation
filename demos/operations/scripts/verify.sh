#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
curl --fail --silent --show-error --cacert certs/server.crt https://localhost:8443/ > /dev/null
curl --fail --silent --show-error http://localhost:3001/api/health
curl --fail --silent --show-error http://localhost:9091/-/ready
printf '\nProbe query (wait at least 30 seconds after startup):\n'
curl --fail --silent --show-error --get http://localhost:9091/api/v1/query \
  --data-urlencode 'query=probe_success{job="https-app"}'
printf '\nExpected: one result with value 1. Empty or 0 is NOT a pass.\n'
