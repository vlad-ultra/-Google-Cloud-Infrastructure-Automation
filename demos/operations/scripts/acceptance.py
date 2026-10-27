#!/usr/bin/env python3
"""Verify this local lab, including recovery of a non-provisioned dashboard."""
import base64
import datetime
import json
import os
from pathlib import Path
import ssl
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
os.chdir(ROOT)
REPORT = ROOT / 'evidence' / 'acceptance.json'
REPORT.parent.mkdir(exist_ok=True)
config = dict(line.split('=', 1) for line in (ROOT / '.env').read_text().splitlines() if '=' in line)
auth = base64.b64encode(('admin:' + config['GRAFANA_ADMIN_PASSWORD']).encode()).decode()
results = {'environment': 'local Docker Desktop lab', 'checks': []}


def request(url, payload=None, authenticated=False):
    headers = {'Content-Type': 'application/json'}
    if authenticated:
        headers['Authorization'] = 'Basic ' + auth
    req = urllib.request.Request(url, data=None if payload is None else json.dumps(payload).encode(), headers=headers)
    with urllib.request.urlopen(req, timeout=10) as response:
        return json.load(response)


def compose(*args, volume=None):
    env = os.environ.copy()
    if volume:
        env['GRAFANA_VOLUME'] = volume
    return subprocess.run(['docker', 'compose', *args], env=env, text=True, capture_output=True, check=True).stdout.strip()


def wait_for(call, expected, timeout=55):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        try:
            value = call()
            if expected(value):
                return value
        except (urllib.error.URLError, OSError, ValueError):
            pass
        time.sleep(2)
    raise RuntimeError('Timed out waiting for expected state')


def record(name, details):
    results['checks'].append({'check': name, 'result': 'PASS', 'details': details})
    REPORT.write_text(json.dumps(results, indent=2) + '\n')
    print('PASS: ' + name, flush=True)


def probe():
    query = urllib.parse.urlencode({'query': 'probe_success{job="https-app"}'})
    rows = request('http://localhost:9091/api/v1/query?' + query)['data']['result']
    return None if not rows else rows[0]['value'][1]


stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
uid = 'infra-lab-restore-proof'
dashboard = {
    'uid': uid, 'title': 'Infrastructure Lab | Restore Proof', 'schemaVersion': 39,
    'tags': ['portfolio', 'local-lab', 'backup-verification'],
    'description': 'Local Docker lab. Saved in Grafana database, not provisioned from a dashboard file. Backup verification marker: ' + stamp,
    'timezone': 'utc', 'refresh': '5s', 'time': {'from': 'now-15m', 'to': 'now'},
    'panels': [
        {'id': 1, 'title': 'HTTPS endpoint reachable', 'type': 'stat', 'gridPos': {'x': 0, 'y': 0, 'w': 8, 'h': 5},
         'datasource': {'type': 'prometheus', 'uid': 'prometheus'},
         'targets': [{'expr': 'probe_success{job="https-app"}', 'refId': 'A', 'instant': True}],
         'fieldConfig': {'defaults': {'min': 0, 'max': 1, 'mappings': [{'type': 'value', 'options': {'0': {'text': 'DOWN', 'color': 'red'}, '1': {'text': 'UP', 'color': 'green'}}}], 'thresholds': {'mode': 'absolute', 'steps': [{'color': 'red', 'value': None}, {'color': 'green', 'value': 1}]}}, 'overrides': []},
         'options': {'colorMode': 'background', 'graphMode': 'none', 'reduceOptions': {'calcs': ['lastNotNull']}}},
        {'id': 2, 'title': 'HTTPS probe duration', 'type': 'stat', 'gridPos': {'x': 8, 'y': 0, 'w': 8, 'h': 5},
         'datasource': {'type': 'prometheus', 'uid': 'prometheus'},
         'targets': [{'expr': 'probe_duration_seconds{job="https-app"}', 'refId': 'A', 'instant': True}],
         'fieldConfig': {'defaults': {'unit': 's', 'decimals': 3}, 'overrides': []}},
        {'id': 3, 'title': 'Lab scope', 'type': 'text', 'gridPos': {'x': 16, 'y': 0, 'w': 8, 'h': 5},
         'options': {'mode': 'markdown', 'content': '### Local portfolio lab\nNginx TLS → ready-made application\n\nPrometheus + Blackbox monitoring\n\nGrafana cold backup → new data volume\n\nSynthetic data · no cloud servers'}},
        {'id': 4, 'title': 'Availability — controlled failure and recovery', 'type': 'timeseries', 'gridPos': {'x': 0, 'y': 5, 'w': 24, 'h': 8},
         'datasource': {'type': 'prometheus', 'uid': 'prometheus'},
         'targets': [{'expr': 'probe_success{job="https-app"}', 'refId': 'A', 'legendFormat': 'HTTPS probe'}],
         'fieldConfig': {'defaults': {'min': 0, 'max': 1, 'custom': {'lineWidth': 3, 'fillOpacity': 15, 'drawStyle': 'line', 'lineInterpolation': 'stepAfter'}}, 'overrides': []}},
    ]
}

try:
    context = ssl.create_default_context(cafile=str(ROOT / 'certs/server.crt'))
    with urllib.request.urlopen('https://localhost:8443/', context=context, timeout=10) as response:
        assert response.status == 200
    record('HTTPS with certificate validation', 'HTTP 200, certificate trusted via lab CA and hostname verified')
    wait_for(probe, lambda value: value == '1')
    record('Initial monitoring', 'Prometheus reports probe_success=1')
    wait_for(lambda: request('http://localhost:3001/api/health'), lambda v: v['database'] == 'ok')
    request('http://localhost:3001/api/dashboards/db', {'dashboard': dashboard, 'overwrite': True}, True)
    record('Saved dashboard', {'uid': uid, 'marker': stamp})
    try:
        compose('stop', 'app')
        wait_for(probe, lambda value: value == '0')
        record('Controlled failure detected', 'Stopped application; Prometheus reports probe_success=0')
    finally:
        compose('start', 'app')
    wait_for(probe, lambda value: value == '1')
    record('Recovery detected', 'Restarted application; Prometheus reports probe_success=1')
    before = set((ROOT / 'backups').glob('grafana-*.tar.gz'))
    subprocess.run(['sh', 'scripts/backup.sh'], capture_output=True, text=True, check=True)
    new = set((ROOT / 'backups').glob('grafana-*.tar.gz')) - before
    assert len(new) == 1, 'Expected exactly one new backup'
    archive = new.pop()
    record('Cold backup', {'file': archive.name, 'bytes': archive.stat().st_size})
    volume = 'devops-demo-restore-' + stamp.lower()
    subprocess.run(['sh', 'scripts/restore.sh', archive.name, volume], capture_output=True, text=True, check=True)
    try:
        compose('up', '-d', '--force-recreate', 'grafana', volume=volume)
        wait_for(lambda: request('http://localhost:3001/api/health'), lambda v: v['database'] == 'ok')
        saved = wait_for(lambda: request('http://localhost:3001/api/dashboards/uid/' + uid, authenticated=True), lambda v: stamp in v['dashboard'].get('description', ''))
        container = compose('ps', '-q', 'grafana', volume=volume)
        mounts = json.loads(subprocess.check_output(['docker', 'inspect', container], text=True))[0]['Mounts']
        assert any(m.get('Name') == volume and m['Destination'] == '/var/lib/grafana' for m in mounts)
        assert saved['dashboard']['title'] == dashboard['title']
        record('Restore into new volume', {'volume': volume, 'dashboard_uid': uid, 'marker_preserved': True, 'authenticated_login': True})
    finally:
        compose('up', '-d', '--force-recreate', 'grafana')
    wait_for(lambda: request('http://localhost:3001/api/health'), lambda v: v['database'] == 'ok')
    wait_for(probe, lambda value: value == '1')
    record('Original environment restored', 'Grafana uses original volume; HTTPS probe is healthy')
    results['status'] = 'PASS'
except Exception as error:
    results['status'] = 'FAIL'
    results['error'] = type(error).__name__ + ': ' + str(error)
    raise
finally:
    results['checked_at_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
    REPORT.write_text(json.dumps(results, indent=2) + '\n')
