# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This project containerizes Interactive Brokers Gateway with IBC (Interactive Brokers Controller) for automated trading. It builds Docker images published to Quay.io with support for multiple channels (stable, latest, nightly) and includes VNC support for debugging.

## Build Commands

### Building Docker Images
```bash
# Build stable channel (fetches latest IBKR version)
./build.sh stable

# Build latest channel (fetches latest IBKR version)
./build.sh latest

# Build nightly channel (uses git commit hash, 1-week expiry)
./build.sh nightly

# Build and push to registry
./build.sh stable --push
./build.sh latest --push
```

### Version Management

The `build.sh` script manages two critical external dependencies:

**1. IB Gateway** (from Interactive Brokers)
- Fetched from IBKR's version endpoint: `https://download2.interactivebrokers.com/installers/ibgateway/{channel}-standalone/version.json`
- Automatically detects latest version for the channel (stable/latest)
- Nightly builds pull from stable channel

**2. IBC** (Interactive Brokers Controller)
- Downloaded from public GitHub releases: `https://github.com/IbcAlpha/IBC/releases/download/{version}/IBCLinux-{version}.zip`
- Versions configured in `build.sh`: `IBC_RELEASE_STABLE=3.23.0`, `IBC_RELEASE_LATEST=3.23.0`
- `Dockerfile` hardcoded `IBC_VERSION=3.23.0`
- **Important**: Keep IBC versions in `build.sh` synchronized with `Dockerfile` hardcoded `IBC_VERSION` (currently synchronized ✅)

### Development and Testing

**Using Docker Compose (Recommended)**
```bash
# Run container with Docker Compose
docker-compose up

# Override local config files for testing
# (automatically mounted via volumes in docker-compose.yaml)
docker-compose up
```

**Manual Build with Custom Versions**
```bash
# Build specific version manually
docker build ./gateway --platform linux/amd64 \
  --build-arg BUILD=<build_version> \
  --build-arg CHANNEL=<channel> \
  --build-arg IBC_VERSION=<ibc_version> \
  -t quay.io/hartza-capital/ib-gateway:<tag>
```

## Architecture

### Multi-stage Docker Build
- **Build stage**: Downloads IB Gateway installer from IBKR and IBC from GitHub releases
- **Runtime stage**: Python 3.14 slim base with X11/VNC support and rootless user setup
- **Process Supervisor**: Copies `unstoppable` and `healthcheck` binaries from `quay.io/hartza-capital/unstoppable:latest`
  - **Note**: The image is **public** on Quay.io, but the source code is private at `/Users/aperrier/go/src/github.com/hartza-capital/unstoppable`
  - Manages gateway lifecycle, auto-restart, and health checks on port 8080
  - No authentication required to pull the image

### Key Components

**IB Gateway**
- Interactive Brokers trading gateway (downloaded from IBKR during build)
- Handles live and paper trading API on ports 4001 and 4002
- Requires IBC for automated startup

**IBC** (Interactive Brokers Controller)
- Public open-source project: [IbcAlpha/IBC on GitHub](https://github.com/IbcAlpha/IBC)
- Automates IB Gateway startup and configuration
- Handles login credentials and trading mode setup
- Downloaded from GitHub releases during build

**Unstoppable**
- Process supervisor (public image on quay.io/hartza-capital/unstoppable)
- Manages IBC and gateway lifecycle with auto-restart
- Provides health checks on port 8080

**X11VNC**
- VNC server for remote GUI access on port 5900
- Allows visual debugging of gateway

**Python environment**
- Python 3.14 slim base for running debug scripts and custom tools

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
- **stable**: Long-lived releases with 12-week expiration, uses IBC 3.21.2
- **latest**: Current release builds, tagged with major/minor versions, uses IBC 3.21.2
- **nightly**: Temporary builds (1-week lifespan) using git commit hash as build ID, uses latest IBC

**Important**: The `build.sh` script defines IBC versions that may differ from the `Dockerfile`. When updating IBC versions, ensure both files are synchronized. The `Dockerfile` currently hardcodes `IBC_VERSION=3.23.0` but this should match the versions used by build.sh for consistency.

### CI/CD Pipeline
- Automated builds on GitHub Actions (weekly Sunday schedule at 5:00 UTC)
- Three workflows: `.github/workflows/build_stable.yml`, `.github/workflows/build_latest.yml`, `.github/workflows/build_nightly.yml`
- Images published to `quay.io/hartza-capital/ib-gateway` with automatic tagging based on channel and version
- Workflows use the `build.sh` script to fetch versions dynamically and tag appropriately
- **Tag format for releases**:
  - Stable: `<build_version>`, `<major>`, `<major>-stable`, `stable`
  - Latest: `<build_version>`, `<major>-latest`, `<minor>`, `latest`
  - Nightly: `<git_short_sha>` only (no additional tags)

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
- `VNC_SERVER_PASSWORD`: VNC access password (default: `test` in docker-compose.yaml)
- `QUAY_EXPIRE`: Label for Quay.io image expiration (set automatically by build.sh)
- Restart policy: `unless-stopped` with `SIGKILL` stop signal

### Local Development Workflow

The `docker-compose.yaml` mounts local files for easy development:

```yaml
volumes:
  - ./gateway/config.ini:/opt/ibc/config.ini           # Override IBC config
  - ./gateway/scripts/gatewaystart.sh:/opt/ibc/scripts/gatewaystart.sh  # Override startup script
```

This allows you to edit `gateway/config.ini` and `gateway/scripts/gatewaystart.sh` locally and have changes reflected in the running container. Changes to other files require a rebuild with `docker-compose up --build`.

### Debug Tools
- Python scripts in `gateway/debug/` for API testing:
  - `contract_details.py`: Contract information queries
  - `contract_fundamental.py`: Fundamental data retrieval  
  - `positions.py`: Position monitoring
  - `requirements.txt`: Python dependencies for debug scripts

## Known Issues and Troubleshooting

### Build and Dependency Issues

**Missing or outdated `unstoppable` image**: The Dockerfile pulls `quay.io/hartza-capital/unstoppable:latest` (public image). If the build fails:
- Check that Quay.io is accessible and the image exists
- If you need a specific version, check available tags on [quay.io/hartza-capital/unstoppable](https://quay.io/repository/hartza-capital/unstoppable)
- The `unstoppable` binary manages process supervision, auto-restart, and health checks (port 8080)
- To modify unstoppable, edit the private source code at `/Users/aperrier/go/src/github.com/hartza-capital/unstoppable`, build, and push a new image

**IBC version updates**: When updating IBC version:
- Update both `IBC_RELEASE_STABLE` and `IBC_RELEASE_LATEST` in `build.sh`
- Update `IBC_VERSION` environment variable in `Dockerfile`
- Verify the version is available on GitHub: `https://github.com/IbcAlpha/IBC/releases/`
- Test all three channels (stable, latest, nightly) after version update

**IBC Download Failures**: 
- Ensure the container build has internet access to GitHub
- GitHub API rate limits may affect downloads in CI/CD (use authenticated requests if needed)
- Check IBC logs at `/home/trader/ibc/logs/` for startup issues
- Verify downloaded ZIP has correct structure and executables
- IBC must have execute permissions (handled by `chmod +x` in Dockerfile)

**Dockerfile glob patterns**: When modifying file permissions in the Dockerfile, use valid glob patterns:
- ✅ `chmod +x /opt/ibc/*.sh` (single `*`)
- ✅ `chmod +x /opt/ibc/**/*.sh` (double `**` for recursive)
- ❌ Avoid patterns that don't match any files (results in chmod failure)

### Platform and Architecture

All builds explicitly target `linux/amd64` via the `--platform` flag. Building for other architectures requires modifications to both the build script and Dockerfile.

## Key Implementation Details

### Entry Point and Service Management

The container entry point is defined by `CMD [ "unstoppable", "-c", "unstoppable.conf" ]`. The `unstoppable` service:
- Manages process supervision and auto-restart of IB Gateway
- Provides health checks via HTTP on port `8080`
- Reads configuration from `/home/trader/unstoppable.conf`
- Monitors gateway health and restarts if needed

The actual gateway startup is handled by `unstoppable` executing the IBC startup script defined in `unstoppable.conf`.

### Script Execution Order

1. Container starts with `unstoppable` as PID 1
2. `unstoppable` starts the X11 VNC server (via `x11vnc.sh`)
3. `unstoppable` starts IB Gateway via IBC (`gatewaystart.sh`)
4. `unstoppable` monitors both processes and reports health

### User Permissions

- All processes run as the `trader` user (UID 10001) with no root access
- IBC logs are written to `/home/trader/ibc/logs/`
- Make sure mounted volumes have appropriate permissions for this user

### Modifying Build Arguments

When updating build arguments or versions:
1. **For `build.sh`-driven builds**: Modify `IBC_RELEASE_STABLE`, `IBC_RELEASE_LATEST` in `build.sh`
2. **For manual Docker builds**: Pass `--build-arg IBC_VERSION=<version>` to `docker build`
3. **For Dockerfile-only changes**: Update the default `ENV IBC_VERSION=...` line (but this should ideally match build.sh)
4. **Test all three channels** after version updates to ensure no regressions