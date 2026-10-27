# Local load-balancing demo

A runnable local counterpart to the routing concept in the archived GCP project: HAProxy routes requests to two Nginx servers using the existing web pages. It requires Docker Compose v2 and Python 3, no GCP account or custom VM images.

```sh
cd demos/load-balancer
docker compose up -d --wait
python3 verify.py
```

Open http://localhost:8088. Inspect the `X-Demo-Backend` HTTP response header, or run `curl -s -D - http://localhost:8088/ -o /dev/null`. The test records ten successful requests per stage: both backends, web1 stopped, and web1 restored. The stopped server is restarted in a finally block. Results are written to validation.json. This briefly stops only this demo's web1 container.

This is a local demonstration, not a current GCP deployment, production SLA or proof that a single HAProxy instance is highly available. The port binds to loopback. Historic cloud images are not used by this mode. Image versions are pinned for reproducibility; check security advisories before production use.

Stop while preserving other projects: `docker compose down` from this directory.
