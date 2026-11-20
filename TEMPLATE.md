# RocketRide 3 AI Pipeline Engine: Railway template spec

## Listing

| Field | Value |
|---|---|
| Name | **RocketRide 3 AI Pipeline Engine** |
| Description | Self-hosted RocketRide engine for AI pipelines, webhooks and MCP, key-gated (75 chars) |
| Category | AI/ML |
| Tags | rocketride, ai-pipelines, rag, agents, mcp, llm, qdrant, vscode |
| Icon | upstream `docs/docusaurus/static/img/rocketride-icon-colored.svg` at server-v3.6.0 via jsDelivr (200, image/svg+xml) |
| Repo | `baranberkay96/rocketride-railway`, service root `/services/engine` |

## Feasibility (checked 2026-11-20)

- **License.** MIT. Upstream says there is no enterprise edition.
- **Server, not only a CLI/SDK.** The engine is a long-running server (`./engine ./ai/eaas.py`, uvicorn on 5565): WebSocket API for the VS Code extension, SDKs and CLI, an MCP server at `/mcp`, webhook and chat endpoints of running pipelines, `/version` as the public health endpoint. Upstream publishes `ghcr.io/rocketride-org/rocketride-engine` per release (amd64, 456 MB compressed).
- **Auth.** With `ROCKETRIDE_APIKEY` set, every client and MCP call needs it; without it the engine accepts any key. The template always sets one (fail closed).
- **No Docker needed.** Each pipeline runs as a child process of the engine. The Kubernetes node image (`rocketride-node`) is for the Helm chart only.
- **GPU.** Local-model nodes depend on `torch==2.10.0+cu128`. The first test filled a 5 GB volume with NVIDIA wheels. The template adds a requirements file with PyTorch's CPU index and an overrides file (`torch==2.10.0+cpu`, `torchvision==0.25.0+cpu`), both picked up by the engine's own `depends.py` globs. The Dockerfile runs `ensure_constraints()` at build (as upstream's node image does) so the engine does not recompile constraints against PyPI at every start.

## Market templates

None existed for RocketRide on 2026-11-20 (`_market` empty).

## Pinned versions

| Component | Reference | Checked |
|---|---|---|
| RocketRide engine | `ghcr.io/rocketride-org/rocketride-engine:3.6.0@sha256:ccb90686…b6cc` (release 2026-11-04; 3.6.0-prerelease of 2026-11-17 not used) | 2026-11-20 |
| Qdrant | `qdrant/qdrant:v1.20.2@sha256:d2775927…cbcac` | 2026-11-20 |

## Services and variables

| Service | Source | Health | Domain | Volume |
|---|---|---|---|---|
| RocketRide | repo `/services/engine` (`FROM` digest + start script + torch overrides) | `/version`, 600 s | public, 5565 | `/opt/data` |
| Qdrant | image (digest) | `/readyz`, 300 s | private | `/qdrant/storage` |

RocketRide: `PORT=5565`, `ROCKETRIDE_APIKEY=rr_${{secret(40)}}`, `RR_PARAM_TOKEN_SECRET` (`secret(48)`), `ROCKETRIDE_QDRANT_HOST=${{Qdrant.RAILWAY_PRIVATE_DOMAIN}}`, `ROCKETRIDE_COLLECTION_NAME=rocketride`, `ROCKETRIDE_LOG_LEVEL=info`. The start script sets `ROCKETRIDE_URI=ws://127.0.0.1:$PORT` (MCP tools of engine ≤3.6.0 otherwise go to RocketRide Cloud), `UV_EXTRA_INDEX_URL` (PyTorch CPU index), `UV_LINK_MODE=copy`, `RR_SUBPROCESS_ENV=UV_*`, chowns the volume to uid 1000 and drops to it with `setpriv`.
Qdrant: `PORT=6333`, `QDRANT__SERVICE__HOST=::`, `QDRANT__STORAGE__STORAGE_PATH=/qdrant/storage`, `QDRANT__TELEMETRY_DISABLED=true`. No API key: the pipelines' `local` Qdrant profile cannot send one; the service has no public domain.

Fallbacks (STANDARD 8.29): an invalid or empty `ROCKETRIDE_APIKEY` locks the engine with a random `rr_` key (deploy succeeds, log explains); an invalid `PORT` becomes 5565.

## Resource profile (measured on Railway, 2026-11-20)

See the test section; idle values are filled from the pre-publish deploy.

## Test results (Railway, pre-publish, 2026-11-20)

- First deploy: both services SUCCESS, `/version` 200. MCP at `/mcp`: no key 401, wrong key 401, generated key 200 (`initialize`), `tools/list` returned 32 tools (`list_components`, `validate_pipeline`, `run_pipeline`, `send_data`, `terminate`, logs, deploy and store tools).
- Running upstream's RAG ingest chain (webhook → parse → chunk → embedding_transformer → Qdrant) through `run_pipeline` failed on that first deploy: the engine installed CUDA PyTorch into a uv cache on the volume and ran out of space. Fixed with the CPU overrides; retest below.

## Verification checklist

1. Both services SUCCESS; `https://{domain}/version` is 200.
2. MCP: `POST /mcp` with `Authorization: Bearer {ROCKETRIDE_APIKEY}` answers `initialize`; without the key 401.
3. Run a pipeline with an embedding node and a Qdrant node (upstream `examples/rag-pipeline.pipe`); the first run installs CPU PyTorch.
4. Connect VS Code (on-premises connection, `wss://{domain}:443`).

## Open questions

- LLM nodes were not run (no provider keys in tests).
- The VS Code extension's remote connection was not tried (no IDE in the test environment); the SDK/CLI address format comes from upstream docs.
