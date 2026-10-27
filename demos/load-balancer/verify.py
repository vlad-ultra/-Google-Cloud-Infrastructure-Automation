#!/usr/bin/env python3
"""Exercise real local round-robin routing, failure detection and recovery."""
import datetime
import json
import os
from pathlib import Path
import subprocess
import time
import urllib.error
import urllib.request
ROOT=Path(__file__).resolve().parent
os.chdir(ROOT)
report={"scope":"local Compose demo; does not validate retired GCP infrastructure","checks":[]}
def compose(*args):
    return subprocess.run(["docker","compose",*args],text=True,capture_output=True,check=True)
def request():
    with urllib.request.urlopen("http://localhost:8088/",timeout=3) as r:
        body=r.read()
        assert r.status==200 and body, "Expected HTTP 200 with a non-empty page"
        return r.headers.get("X-Demo-Backend")
def wait_for(expected):
    deadline=time.monotonic()+30
    while time.monotonic()<deadline:
        try:
            seen=[request() for _ in range(10)]
            if set(seen)==set(expected):return seen
        except (urllib.error.URLError,OSError,AssertionError):pass
        time.sleep(1)
    raise AssertionError("Expected backends not observed: "+str(expected))
def record(name,seen):
    report["checks"].append({"name":name,"result":"PASS","observed_backends":seen})
    print("PASS: "+name+" -> "+", ".join(seen),flush=True)
try:
    record("Round-robin across two servers",wait_for(["web1","web2"]))
    try:
        compose("stop","web1")
        record("Failover with web1 stopped",wait_for(["web2"]))
    finally:
        compose("start","web1")
    record("Both servers after recovery",wait_for(["web1","web2"]))
    report["status"]="PASS"
except Exception as e:
    report["status"]="FAIL";report["error"]=str(e)
    raise
finally:
    report["checked_at_utc"]=datetime.datetime.now(datetime.timezone.utc).isoformat()
    (ROOT/"validation.json").write_text(json.dumps(report,indent=2)+"\n")
