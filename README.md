# Deploy and Host RocketRide with Railway

RocketRide is an open-source AI pipeline engine with a C++ runtime: you build pipelines of LLMs, agents, parsers, vector stores and tools in VS Code or with its SDKs, and run them on the engine. This community template runs your own RocketRide 3.6 engine behind an API key, with a Qdrant vector database next to it.

## About Hosting RocketRide

The RocketRide engine is a server on port 5565. Clients connect over a WebSocket (VS Code extension, Python and TypeScript SDKs, CLI), AI assistants use its built-in MCP server at `/mcp`, and running pipelines receive data at webhook and chat endpoints on the same port. Each running pipeline is its own process; the Python packages a node needs are installed on first use. Without an API key the engine accepts any key, so this template generates one and refuses to start the engine without a valid key. Upstream's image ships the CUDA build of PyTorch for local-model nodes; on Railway, which has no GPUs, the template switches those nodes to the CPU build through the engine's own override files.

## Common Use Cases

- A shared remote engine for a team building pipelines in VS Code or Cursor
- Retrieval (RAG) pipelines: chunk and embed documents into Qdrant, then answer questions with an LLM
- Webhook and chat endpoints for your apps, backed by a pipeline
- An MCP server that lets Claude, Cursor or other assistants list, validate and run your pipelines

## Dependencies for RocketRide Hosting

- RocketRide engine 3.6.0 (`ghcr.io/rocketride-org/rocketride-engine`, pinned by digest) with a start script
- Qdrant 1.20.2 as the pipelines' vector store (private)
- API keys for the model providers your pipelines use (OpenAI, Anthropic and others), set as variables

### Deployment Dependencies

- RocketRide source: https://github.com/rocketride-org/rocketride-server
- Documentation: https://docs.rocketride.org
- Self-hosting with Docker: https://docs.rocketride.org/operate/self-hosting/docker
- VS Code extension: https://marketplace.visualstudio.com/items?itemName=RocketRide.rocketride
- Qdrant: https://qdrant.tech/documentation

### Implementation Details

| Service | Source | Purpose |
|---|---|---|
| RocketRide | engine image + start script (`services/engine`) | WebSocket API, `/mcp`, webhook and chat endpoints on port 5565 (public domain); task data on a volume at `/opt/data`; healthcheck `/version` |
| Qdrant | `qdrant/qdrant:v1.20.2` (digest-pinned) | Vector store for pipelines, private network only, volume `/qdrant/storage` |

**Connect a client.** Copy `ROCKETRIDE_APIKEY` from the RocketRide service's Variables tab. Clients use `wss://{your-domain}:443` with that key (name the port: clients add 5565 to an address without one), for example `ROCKETRIDE_URI=wss://{your-domain}:443` and `ROCKETRIDE_APIKEY={key}` for the SDKs and CLI. In the VS Code extension, add an on-premises connection with the same address and key.

**MCP.** Point an MCP client at `https://{your-domain}/mcp` with the header `Authorization: Bearer {key}`. It offers tools to list components, validate, run and stop pipelines and read their logs.

**Webhooks and chat.** A running pipeline with a Webhook source answers at `https://{your-domain}/webhook/{project}/{source}`, and a Chat source has a page at `/chat/{project}/{source}`; the engine prints their keys in the pipeline's log.

**Provider keys.** Pipelines reference keys as `${ROCKETRIDE_...}` variables (only names starting with `ROCKETRIDE_` are substituted). Add them to the RocketRide service, for example `ROCKETRIDE_OPENAI_KEY`, and redeploy.

**Vector store.** `ROCKETRIDE_QDRANT_HOST` points at the Qdrant service and `ROCKETRIDE_COLLECTION_NAME` names the default collection, which is what upstream's `examples/rag-pipeline.pipe` expects. Qdrant has no public domain and no API key, so only services in this project reach it.

**Local models.** Nodes that run models on the engine (embeddings, OCR, NER and others) install PyTorch the first time they run. The template's override files install the CPU build, about 200 MB instead of several GB of CUDA libraries. Installed packages live in the container, so the first run after a redeploy installs them again.

**Safe defaults.** `ROCKETRIDE_APIKEY` is generated (`rr_` plus 40 characters). If it is empty or not `rr_` followed by 16 to 200 letters, digits, `_` or `-`, the engine starts with a random key nobody knows and the log says how to fix it; the deploy still succeeds. `RR_PARAM_TOKEN_SECRET` encrypts the secure parameters saved in pipelines; keep it.

**Resources.** Measured on Railway: the engine idles at about 0.15 GB and Qdrant at about 0.05 GB. A running pipeline is a separate process; local-model nodes need 1 GB or more while they work. Use the Hobby plan or higher for local models.

**Upgrades.** Change the engine digest in `services/engine/Dockerfile` (keep the PyTorch versions in the override files equal to the ones in the new engine's `ai/common/torch/requirements.txt`) and the Qdrant tag in the template.

This is a community template, not affiliated with RocketRide or Aparavi. RocketRide is MIT-licensed. Follow Railway's Fair Use Policy.

### Why Deploy RocketRide on Railway?

Railway gives the engine an HTTPS domain, a volume and a private vector database in one project, so your team, your apps and your AI assistants can share one always-on engine instead of each running a local one. You deploy, copy the key, and connect from VS Code, the SDKs or MCP.
