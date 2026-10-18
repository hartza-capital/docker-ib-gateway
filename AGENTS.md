# AGENTS.md

This file provides guidance to coding agents (Claude Code, Hermes, ...) when working with code in this repository.

## Project Overview

This project containerizes Interactive Brokers Gateway with IBC (Interactive Brokers Controller) for automated trading. It builds Docker images published to Quay.io with support for two channels (stable, latest) and includes VNC support for debugging.

Everything that ships in the image lives under `gateway/`; the repo root holds only `build.sh`, `docker-compose.yaml`, `README.md` and CI. There is nothing to compile, no test suite and no Makefile — the deliverable is the image itself.

## Build Commands

`build.sh` needs `docker` (buildx), `curl` and `jq` on `PATH`: it reads `buildVersion` from IBKR's `version.json` before building.

### Building Docker Images

```bash
# Build by channel (fetches latest IBKR version automatically)
./build.sh stable
./build.sh latest

# Build and push to registry
./build.sh stable --push
./build.sh latest --push
```

Usage is `./build.sh <stable|latest> [--push]`; any other channel exits 1 (the former `nightly` channel was removed).

### Version Management

`build.sh` resolves one dependency and delegates the other:

**IB Gateway** — fetched from IBKR's version endpoint during build; `build.sh` reads `buildVersion` from that endpoint and passes it to the image as `BUILD`.

**IBC** (Interactive Brokers Controller) — upstream [IbcAlpha/IBC](https://github.com/IbcAlpha/IBC) is **archived** (the author retired; last upstream release `3.24.2`), so no further upstream versions will appear. This project ships from our own maintained repo, `https://github.com/hartza-capital/IBC` (standalone repo, not a GitHub fork): the Dockerfile downloads `IBCLinux-${IBC_VERSION}.zip` from its releases. Its version has a single source of truth: `ARG IBC_VERSION` in `gateway/Dockerfile` (currently `3.25.1`, already ahead of upstream). `build.sh` does not pass it, so the Dockerfile default is what ships.

When updating IBC: tag and verify the release in `hartza-capital/IBC` first, then bump `ARG IBC_VERSION`. Nothing can be pulled from upstream any more — do not repoint the download at `IbcAlpha/IBC`.

Image metadata: `org.opencontainers.image.version` is `<build>-<channel>` (e.g. `10.50.1f-stable`). Both `ARG BUILD` and `ARG CHANNEL` must be declared in the runtime stage as well — build args and env vars do not cross a `FROM` boundary. `latest` builds set `quay.expires-after=12w`; `stable` leaves the Dockerfile default of `never`.

### Development and Testing

`docker-compose.yaml` runs the **published** stable image — it has no `build:` section, so `docker-compose up --build` rebuilds nothing:

```bash
# Run the published stable image with local config.ini / gatewaystart.sh mounted
docker-compose up

# Test an image built locally: ./build.sh already tags :stable, so compose picks it up
./build.sh stable
```

Manual build with explicit versions:

```bash
docker build ./gateway --platform linux/amd64 \
  --build-arg BUILD=<build_version> \
  --build-arg CHANNEL=<channel> \
  --build-arg IBC_VERSION=<ibc_version> \
  -t quay.io/hartza-capital/ib-gateway:<tag>
```

`IBC_VERSION` is optional and defaults to the value set in the Dockerfile.

There is no automated test command. Verification is: `docker logs <container>`, `docker exec <container> tail -f /home/trader/ibc/logs/ibc.log`, then an API connection — the scripts in `gateway/debug/` are the smoke tests.

## Architecture

### Multi-stage Docker Build

- **Build stage** (`debian:stable-slim`): Downloads IB Gateway installer and IBC zip from their respective sources
- **Runtime stage** (`debian:stable-slim`): X11/VNC support, rootless `trader` user (UID 10001)
- **Unstoppable binaries**: Copied from `quay.io/hartza-capital/unstoppable:latest` (public image; source is private)

### Startup Sequence

1. Container starts with `unstoppable` as PID 1, reading `unstoppable.conf`
2. `unstoppable` starts `x11vnc.sh` (X11 virtual display + VNC server)
3. `unstoppable` starts IB Gateway via IBC (`gatewaystart.sh -inline`)
4. `unstoppable` monitors both processes with auto-restart and exposes health on port 8080

### Key Components

| Component   | Purpose                            | Source                                                      |
| ----------- | ---------------------------------- | ----------------------------------------------------------- |
| IB Gateway  | Trading API (ports 4001/4002)      | Downloaded from IBKR during build                           |
| IBC         | Automates gateway startup/login    | [hartza-capital/IBC](https://github.com/hartza-capital/IBC) |
| Unstoppable | Process supervisor + health checks | `quay.io/hartza-capital/unstoppable:latest`                 |
| X11VNC      | Remote GUI access (port 5900)      | Installed via apt                                           |

### Port Mapping

- `4001`: Gateway Live Trading API
- `4002`: Gateway Paper Trading API
- `5900`: VNC server
- `8080`: Unstoppable health check endpoint

### Configuration Files

Each local file has one destination inside the image — an edit only lands if the mount path matches it:

| Local file                        | Image path                                        |
| --------------------------------- | ------------------------------------------------- |
| `gateway/config.ini`              | `/opt/ibc/config.ini` (credentials, trading mode) |
| `gateway/scripts/gatewaystart.sh` | `/opt/ibc/gatewaystart.sh` (replaces IBC's copy)  |
| `gateway/scripts/x11vnc.sh`       | `/home/trader/x11vnc.sh`                          |
| `gateway/unstoppable.conf`        | `/home/trader/unstoppable.conf`                   |

`gateway/debug/` is excluded from the image by `gateway/.dockerignore`.

### CI/CD and Tag Format

Two workflows in `.github/workflows/` (`build_stable.yml`, `build_latest.yml`), each triggered by a push to `main` **and** the weekly schedule (Sunday 05:00 UTC). Both simply run `./build.sh <channel> --push`.

| Channel | Tags pushed                            |
| ------- | -------------------------------------- |
| stable  | `<build_version>`, `<major>`, `stable` |
| latest  | `<build_version>`, `<minor>`, `latest` |

Note: `build.sh` also creates a `<major>-<channel>` local tag (e.g. `10-stable`) but does not push it. The `<minor>` tag carries no channel suffix, so the two workflows overwrite it — whichever runs last owns `10.50`.

### Security Model

- Runs as rootless user `trader` (UID 10001)
- VNC requires `VNC_SERVER_PASSWORD` env var; without it `x11vnc.sh` starts an unauthenticated server
- IBC credentials via `IbLoginId`/`IbPassword` in `config.ini` or environment
- The committed `config.ini` ships `TradingMode=live` with empty credentials, and the README's `test` VNC password is a dev placeholder only

## Conventions

- Shell scripts are bash (`#!/bin/bash` in `gateway/scripts/`), with `#!/usr/bin/env bash` + `set -euo pipefail` in `build.sh`; `.gitattributes` pins `*.sh` to LF, so keep CRLF out.
- Commits follow Conventional Commits with a scope naming the touched area: `fix(build): …`, `fix(gateway): …`, `chore(build): …`, `feat(docs): …`, `hotfix(readme): …`; the PR number is appended on squash-merge (`… (#23)`).
- Branches are `<type>/<slug>`, usually with the issue number: `feature/23-debian-runtime-base`, `improve/update-dependencies-and-docs`, `fix/workflow`.
- Markdown/JSON/YAML are formatted with Prettier via `.prettierrc.json` (printWidth 80, no semicolons, LF). No CI step enforces it — run `npx prettier --write .`.
- `README.md` is user-facing, this file is agent-facing; update both in the same PR when behaviour changes.

## Known Issues and Troubleshooting

**Dockerfile glob patterns**: `chmod` in the Dockerfile must match existing files or the build fails.

- The current line is `chmod +x ./*.sh /opt/ibc/**.sh` — under the Dockerfile's `/bin/sh` (dash) `**` is **not** recursive, it behaves like `*`, so only `/opt/ibc/*.sh` is covered.
- `/opt/ibc/scripts/*.sh` (`ibcstart.sh`, `displaybannerandlaunch.sh`) are executable only because `unzip` preserves the modes stored in the release zip; a re-packaged zip without exec bits breaks startup.

**docker-compose mounts `gatewaystart.sh` at the wrong path**: compose targets `/opt/ibc/scripts/gatewaystart.sh`, but `unstoppable.conf` runs `./gatewaystart.sh` from `/opt/ibc` — local edits to that script have no effect under `docker-compose up`. Mount it at `/opt/ibc/gatewaystart.sh` to iterate on it.

**No Makefile, no tests**: `.github/PULL_REQUEST_TEMPLATE.md` still lists `make lint` / `make test` / `make format-check`. Those targets do not exist here; replace the checkboxes with what you actually ran (image build + gateway login + API connect).

**Unstoppable image unavailable**: If the build fails pulling `quay.io/hartza-capital/unstoppable:latest`, check Quay.io availability. To modify unstoppable itself, edit the private source repo and push a new image.

**IBC download failures in CI**: GitHub rate limits can affect unauthenticated downloads. IBC logs at `/home/trader/ibc/logs/` for runtime startup issues.

**Paper mode / new API clients stall at a dialog**: `config.ini` leaves `AcceptNonBrokerageAccountWarning=no` and `AcceptIncomingConnectionAction=manual`, so switching to `TradingMode=paper` or connecting from a new IP needs a click-through in the Gateway UI over VNC. Gateway settings are not persisted (no volume for `~/Jts`), so this repeats with every new container. `enableapi.sh` from the IBC zip is inside the image if API access reports as disabled.

**Platform**: All builds target `linux/amd64` explicitly. Other architectures require changes to both `build.sh` and `Dockerfile`.

## Debug Tools

Python scripts in `gateway/debug/` for testing against a running gateway:

- `contract_details.py`: Contract information queries
- `positions.py`: Position monitoring
- `requirements.txt`: Python dependencies (`ib_insync==0.9.80`)

Both scripts hardcode `127.0.0.1:4001`, `clientId=200`, `readonly=True` — they target the **live** API port, so point them at `4002` when checking a paper gateway.

<!-- REPOWISE_AGENTS:START — Do not edit below this line. Auto-generated by Repowise. -->
## Codebase Intelligence for docker-ib-gateway (Repowise)

Indexed by [Repowise](https://repowise.dev). Last indexed: 2026-09-27 (commit 563d8b0). Confidence: 93%.Scope: standard index · model content · full Git. Missing or unavailable evidence is not a negative finding. Machine-readable scope: `{"analysis": {"skipped": [], "unavailable": []}, "content_provenance": "model", "file_pages": {"configured_cap": null, "effective_cap": null, "eligible": 2, "generated": 2, "omitted": 0}, "git_commit_cap": 500, "git_history_coverage": {"complete_through_depth": 42, "deep_commits": 0, "deep_files": 0, "eligible_files": 5, "fallback_files": 0, "files_with_history": 5, "global_commits": 42, "per_file_limit": 500, "recent_files": 5, "retained_commits": 24, "unavailable_files": 0, "workers": 5}, "git_tier": "full", "provider": {"embedder": "ollama", "model": "deepseek-v4.1-flash:cloud", "model_cost_possible": true, "name": "ollama", "reused": false}, "run_mode": "standard", "search": {"full_text": "available", "next_command": "repowise reindex", "semantic": "available"}, "upgrade": {"completed_stages": [], "next_stage": null, "retryable": false, "status": "not_applicable"}, "version": 1}`

### How to work in this repo

- **Trust the index.** `verified: true` and `_meta.complete` mean the bytes were checked against the live tree, so never re-read them. Re-read only what `bounds: "approximate"` or `_meta.stale_warning` names. `confidence` rates the prose, not the evidence: on `low` read the `fallback_targets` or `best_guesses` the reply names, and run `repowise update` and ask again if `_meta.hint` says the index is behind HEAD. `index_behind: true` alone is informational.
- **A zero carries its basis.** An empty `callers`/`callees`/`used_by` comes with a `*_basis` saying how much of that language's calls the graph resolved, so read it before concluding nothing calls a symbol. `_meta.scope_hint` names the areas the answer did not touch.
- **Pre-edit, not instead-of-edit.** These tools decide *which* files to read and edit. Reading a file before you edit it is correct and expected.
- **Noisy commands** (tests, builds, `git log`/`diff`, searches, listings): prefer `repowise distill <cmd>`, the same command with its exit code preserved and errors-first output. A `[repowise#<ref>: N lines omitted]` marker is recoverable via `repowise expand <ref>` (add `-q <regex>` to filter); never re-run the command to see omitted output.
- **Recording a decision** you had to reason out: `repowise decision add --title T --decision D` records it without prompting and prints the id (`--format json` to parse it back). It lands `proposed`, for a person to confirm.

### Tools

| Tool | When and why |
|------|--------------|
| `get_answer(question)` | First call for any how/where/why question. Cite `confidence: "high"` or `grounding: "extracted"` directly; `degraded` means judge by `retrieval_quality`. `symbol_bodies` has live bodies. |
| `get_context(targets=[...])` | Triage card for files/modules/symbols: docs, signatures, hotspot, fix history. No source bytes — `include=["skeleton"]` for the whole file verified, `["callers"|"decisions"]` for depth. Batch targets. |
| `get_symbol(id, depth?)` | **Follow-up, not an entry point** — one verified body for an id a prior response named (`path.py::Name`, `path.py:140-180`, `repowise#<hex>`). Never walk a file symbol by symbol; Read it. |
| `search_codebase(query)` | Hybrid search, auto-routed by query shape; force with `mode=symbol|path|concept|hybrid`. A hit whose `sources` are `[fts]` only has no semantic agreement, so verify it. |
| `get_why(query, targets?)` | Why the code is shaped this way: decision records, git archaeology, rationale comments. Call before a refactor or a pattern divergence. |
| `get_risk(targets, changed_files?, include?)` | File history and structural reach. PR mode leads with `directive`; its 0-10 structural heuristic is uncalibrated, not a probability. Read typed test recommendations and coverage state first. |
| `get_change_risk(revspec?, extensions?, exclude_patterns?)` | Deterministic live-diff review signal for a commit or range. Lead with benchmarked percentile/classification; the 0-10 diff-shape score is supporting, not a probability. `get_risk` scores paths. |
| `get_health(targets?, include?)` | Defect / maintainability / performance scores and findings, plus documentation the code no longer supports. Self-check the files you touched before finishing. |
| `get_dead_code(tier?, min_confidence?, safe_only?)` | Confidence-tiered unreachable files / unused exports / zombie packages. For cleanup sweeps, not targeted fixes. |
| `get_overview()` | Architecture map. Call once, first, in an unfamiliar repo; skip it after that. |

### Architecture
docker-ib-gateway is a containerised trading-gateway appliance: it takes Interactive Brokers' **IB Gateway** and **IBC** (Interactive Brokers Controller) as inputs, bakes them into a multi-stage Docker image together with a process supervisor, startup scripts and a VNC server, and emits a headless, self-restarting gateway that publishes the IB trading API on ports 4001 (live) and 4002 (paper), a VNC desktop on 5900 for debugging, and a health endpoint on 8080. The build itself is parameterised by channel and by dynamically fetched upstream versions, and the resulting images are published to Quay.io so that consumers never build anything themselves. The repository deliberately combines three distinct views of the same artifact rather than one scanner or one score. The **build and release view** is the maintenance path: channel-aware version resolution, multi-stage image assembly, and scheduled CI that republishes stable and latest every Sunday so that long-lived releases never hit IBKR's twelve-week expiration.

### Key modules
- `gateway/debug` — The package is small — two files, seven symbols between them — but it carries disproportionate weight in the dependency graph, registering…

### Code health
Three co-equal signals: code health 9.64/10 avg (Excellent), hotspot health 9.64/10 (stable), worst `build.sh` at 9.3/10 · maintainability 10.0/10 · performance risk 0 open static I/O-in-loop / N+1 findings. Detail: `get_health()`.

<!-- REPOWISE_AGENTS:END -->
