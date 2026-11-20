# Notice

This package is a Railway template for RocketRide. It is a community template and is not affiliated with or endorsed by RocketRide or Aparavi Software AG.

## RocketRide

- Source: https://github.com/rocketride-org/rocketride-server, release `server-v3.6.0` (commit ba6b8ef, 2026-11-04)
- License: MIT, Copyright (c) 2026 RocketRide (the engine's start banner also names Aparavi Software AG).
- Used here as the published image `ghcr.io/rocketride-org/rocketride-engine:3.6.0@sha256:ccb906861322f967a5c896940f2ef6bdc80898fee9ac866c473d921e1eb9b6cc`, unmodified, with two small files added to its override folders (`/opt/rocketride/ai/railway/requirements.txt` and `overrides.txt`) that select the CPU build of the PyTorch version the engine pins.
- Upstream files checked: `docker/docker-compose.yml`, `docker/Dockerfile.engine`, `docker/Dockerfile.engine-base`, `docs/public/product/operate/self-hosting/{index,docker,production}.md`, `docs/public/product/operate/security.md`, `docs/public/product/connect/websocket/index.md`, `packages/ai/src/ai/eaas.py`, `packages/ai/src/ai/common/torch/requirements.txt`, `packages/server/engine-lib/rocketlib-python/lib/depends.py`, `examples/rag-pipeline.pipe`.
- PyTorch CPU wheels come from https://download.pytorch.org/whl/cpu (BSD-3-Clause) when a pipeline first needs them.

## Qdrant

- Image `qdrant/qdrant:v1.20.2@sha256:d277592721d2e3b73f9b797b53cf05e6a5bb2134f6d13fdbda4ca51782afbcac`, Apache-2.0, unmodified.

## Files written for this template (MIT, this repository)

- `services/engine/Dockerfile`, `services/engine/railway-start.sh`
- `template.json`, `TEMPLATE.md`, `README.md`

No marketplace template for RocketRide existed when this one was made.
