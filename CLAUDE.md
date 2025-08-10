# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project containerizes Interactive Brokers Gateway with IBC (Interactive Brokers Controller) for automated trading. It builds Docker images published to Quay.io with support for multiple channels (stable, latest, nightly) and includes VNC support for debugging.

## Build Commands

### Building Docker Images
```bash
# Build stable channel
./build.sh stable

# Build latest channel  
./build.sh latest

# Build nightly channel (uses git commit hash)
./build.sh nightly

# Build and push to registry
./build.sh stable --push
./build.sh latest --push
```

### Development and Testing
```bash
# Run container with Docker Compose
docker-compose up

# Build specific version manually
docker build ./gateway --platform linux/amd64 \
  --build-arg BUILD=<build_version> \
  --build-arg CHANNEL=<channel> \
  --build-arg IBC_RELEASE=<ibc_version> \
  -t quay.io/hartza-capital/ib-gateway:<tag>
```

## Architecture

### Multi-stage Docker Build
- **Build stage**: Downloads IB Gateway installer and IBC from GitHub releases
- **Runtime stage**: Python 3.13 base with X11/VNC support and rootless user setup

### Key Components
- **IB Gateway**: Interactive Brokers trading gateway (downloaded from IBKR)
- **IBC**: Automation controller for gateway startup/management
- **Unstoppable**: Process supervisor for service management and health checks
- **X11VNC**: VNC server for remote GUI access on port 5900
- **Python environment**: For running debug scripts and custom tools

### Port Mapping
- `4001`: Gateway Live Trading API
- `4002`: Gateway Paper Trading API  
- `5900`: VNC server for GUI access
- `8080`: Unstoppable health check endpoint

### Configuration Files
- `gateway/config.ini`: IBC configuration (authentication, trading mode, auto-restart settings)
- `gateway/unstoppable.conf`: Process supervisor configuration
- `gateway/scripts/gatewaystart.sh`: IB Gateway startup script
- `gateway/scripts/x11vnc.sh`: VNC server initialization script

### Build Channels
- **stable**: Long-lived releases with 12-week expiration, uses specific IBC versions
- **latest**: Current release builds, tagged with major/minor versions
- **nightly**: Temporary builds (1-week lifespan) using git commit hash as build ID

### CI/CD Pipeline
- Automated builds on GitHub Actions (weekly Sunday schedule at 5:00 UTC)
- Three workflows: `build_stable.yml`, `build_latest.yml`, `build_nightly.yml`
- Images published to `quay.io/hartza-capital/ib-gateway` with automatic tagging

### Security Model
- Runs as rootless user `trader` (UID 10001)
- IBC configuration supports authentication via environment variables or config file
- VNC server requires password authentication via `VNC_SERVER_PASSWORD` environment variable

## Configuration Management

### IBC Settings (config.ini)
- Authentication: `IbLoginId`, `IbPassword` for credentials
- Trading mode: `TradingMode=live` or `paper`  
- Auto-restart: `AutoRestartTime` for daily gateway restarts
- Session management: `ExistingSessionDetectedAction` for handling concurrent sessions

### Docker Compose Variables
- `VNC_SERVER_PASSWORD`: VNC access password
- Volume mounts for custom configuration files
- Restart policy: `unless-stopped` with `SIGKILL` stop signal

### Debug Tools
- Python scripts in `gateway/debug/` for API testing:
  - `contract_details.py`: Contract information queries
  - `contract_fundamental.py`: Fundamental data retrieval  
  - `positions.py`: Position monitoring
  - `requirements.txt`: Python dependencies for debug scripts