# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project containerizes Interactive Brokers Gateway with IBC (Interactive Brokers Controller) for automated trading. It builds Docker images published to Quay.io with support for multiple channels (stable, latest, nightly) and includes VNC support for debugging.

## Build Commands

### Building Docker Images

```bash
# Build by channel (fetches latest IBKR version automatically)
./build.sh stable
./build.sh latest
./build.sh nightly   # uses git commit hash as BUILD, 1-week expiry

# Build and push to registry
./build.sh stable --push
./build.sh latest --push
```

### Version Management

`build.sh` manages two critical external dependencies:

**IB Gateway** — fetched from IBKR's version endpoint during build. Nightly uses the stable IBKR channel (not a separate nightly IBKR build).

**IBC** (Interactive Brokers Controller) — downloaded from GitHub releases. Versions are defined in two places that must stay in sync:

- `build.sh`: `IBC_RELEASE_STABLE` and `IBC_RELEASE_LATEST` (currently both `3.23.0`)
- `gateway/Dockerfile`: `ENV IBC_VERSION=3.23.0`

When updating IBC: change all three variables and verify the release exists at `https://github.com/IbcAlpha/IBC/releases/`.

### Development and Testing

```bash
# Run with Docker Compose (mounts local config.ini and gatewaystart.sh for live editing)
docker-compose up

# Rebuild after Dockerfile changes
docker-compose up --build

# Manual build with explicit versions
docker build ./gateway --platform linux/amd64 \
  --build-arg BUILD=<build_version> \
  --build-arg CHANNEL=<channel> \
  --build-arg IBC_VERSION=<ibc_version> \
  -t quay.io/hartza-capital/ib-gateway:<tag>
```

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

| Component   | Purpose                            | Source                                                          |
| ----------- | ---------------------------------- | --------------------------------------------------------------- |
| IB Gateway  | Trading API (ports 4001/4002)      | Downloaded from IBKR during build                               |
| IBC         | Automates gateway startup/login    | [IbcAlpha/IBC](https://github.com/IbcAlpha/IBC) GitHub releases |
| Unstoppable | Process supervisor + health checks | `quay.io/hartza-capital/unstoppable:latest`                     |
| X11VNC      | Remote GUI access (port 5900)      | Installed via apt                                               |

### Port Mapping

- `4001`: Gateway Live Trading API
- `4002`: Gateway Paper Trading API
- `5900`: VNC server
- `8080`: Unstoppable health check endpoint

### Configuration Files

- `gateway/config.ini`: IBC config (credentials, trading mode, auto-restart time)
- `gateway/unstoppable.conf`: Process supervisor config (log format, health port, program definitions)
- `gateway/scripts/gatewaystart.sh`: IB Gateway startup script (mounted in docker-compose)
- `gateway/scripts/x11vnc.sh`: VNC server init

### CI/CD and Tag Format

Weekly GitHub Actions builds (Sunday 05:00 UTC) via three workflows in `.github/workflows/`.

| Channel | Tags pushed                            |
| ------- | -------------------------------------- |
| stable  | `<build_version>`, `<major>`, `stable` |
| latest  | `<build_version>`, `<minor>`, `latest` |
| nightly | `<git_short_sha>` only                 |

Note: `build.sh` also creates a `<major>-<channel>` local tag (e.g. `10-stable`) but does not push it.

### Security Model

- Runs as rootless user `trader` (UID 10001)
- VNC requires `VNC_SERVER_PASSWORD` env var
- IBC credentials via `IbLoginId`/`IbPassword` in `config.ini` or environment

## Known Issues and Troubleshooting

**Dockerfile glob patterns**: `chmod` in the Dockerfile must match existing files or the build fails.

- `chmod +x /opt/ibc/*.sh` — matches files directly in `/opt/ibc/`
- `chmod +x /opt/ibc/**/*.sh` — matches recursively

**Unstoppable image unavailable**: If the build fails pulling `quay.io/hartza-capital/unstoppable:latest`, check Quay.io availability. To modify unstoppable itself, edit the private source repo and push a new image.

**IBC download failures in CI**: GitHub rate limits can affect unauthenticated downloads. IBC logs at `/home/trader/ibc/logs/` for runtime startup issues.

**Platform**: All builds target `linux/amd64` explicitly. Other architectures require changes to both `build.sh` and `Dockerfile`.

## Debug Tools

Python scripts in `gateway/debug/` for testing against a running gateway:

- `contract_details.py`: Contract information queries
- `positions.py`: Position monitoring
- `requirements.txt`: Python dependencies (`ib_insync`)
