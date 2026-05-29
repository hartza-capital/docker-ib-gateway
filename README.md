<!-- filepath: /Users/perriea/go/src/github.com/hartza-capital/docker-ib-gateway/README.md -->

# Docker IB Gateway

## What is it?

A project that containerizes **IB Gateway** (Interactive Brokers Gateway) with **IBC** (Interactive Brokers Controller) to enable automated trading without a graphical interface.

This project is based on [extrange/ibkr-docker](https://github.com/extrange/ibkr-docker) but with a different approach by **Hartza Capital**.

## Build Status

![Latest](https://github.com/hartza-capital/docker-ib-gateway/actions/workflows/build_latest.yml/badge.svg?branch=main)
![Stable](https://github.com/hartza-capital/docker-ib-gateway/actions/workflows/build_stable.yml/badge.svg?branch=main)

## Main Features

- **Fully containerized**: IB Gateway + IBC in a complete Docker container
- **Automated startup**: Gateway startup is handled by [IBC (Interactive Brokers Controller)](https://github.com/IbcAlpha/IBC)
- **Auto-restart**: Automatic restart on disconnection (like IB's daily disconnect)
- **VNC support**: GUI access via VNC for debugging
- **Multi-channel**: Support for `stable`, `latest`, and `nightly` versions
  - **`stable` & `latest`**: Long-lived releases (12 weeks expiration). Weekly builds on Sundays
  - **`nightly`**: Temporary builds (1-week lifespan) for testing advanced versions
- **Python scripts**: Debugging tools in debug to test API connections
- **Weekly releases**: Automated releases on `stable` and `latest` channels every Sunday
- **Cloud-ready**: Works perfectly on AWS ECS/Kubernetes. Hartza Capital uses a customized version on AWS ECS in production
- **Extensible**: You can add your own custom scripts within the container (though this is generally considered a bad practice, it's the simplest approach given the gateway's security criticality and IBKR gateway's rigidity)

## Project Structure

- **build.sh**: Automated build script that handles different channels and fetches versions dynamically
- **docker-compose.yaml**: Configuration to start the container easily with volume mounts for local development
- **gateway/Dockerfile**: Multi-stage build with IB Gateway, IBC, and process supervisor
- **gateway/config.ini**: IBC configuration for automation
- **gateway/unstoppable.conf**: Process supervisor configuration for service management
- **gateway/scripts/**: Startup and VNC initialization scripts
- **.github/workflows/**: Automated CI/CD (build_stable.yml, build_latest.yml, build_nightly.yml) to build and publish images to [Quay.io](https://quay.io/repository/hartza-capital/ib-gateway?tab=tags)

## Quick Start

### Using Docker Compose (Recommended)

1. Clone the repository:

```bash
git clone https://github.com/hartza-capital/docker-ib-gateway.git
cd docker-ib-gateway
```

2. Configure your credentials in `gateway/config.ini`:

```ini
IbLoginId=your_username
IbPassword=your_password
TradingMode=paper  # or 'live' for production
```

3. Start the container:

```bash
docker-compose up -d
```

4. Access VNC GUI (optional) at `localhost:5900` with password `test`
5. Connect your trading application to API on ports `4001` (live) or `4002` (paper)

### Using Pre-built Images

Pull and run directly from Quay.io:

```bash
# Stable channel (recommended for production)
docker run -d \
  -p 5900:5900 -p 4001:4001 -p 4002:4002 \
  -e VNC_SERVER_PASSWORD=test \
  quay.io/hartza-capital/ib-gateway:stable

# Latest channel (most recent features)
docker run -d \
  -p 5900:5900 -p 4001:4001 -p 4002:4002 \
  -e VNC_SERVER_PASSWORD=test \
  quay.io/hartza-capital/ib-gateway:latest
```

### Building from Source

Build your own image:

```bash
# Build stable channel
./build.sh stable

# Build and push to your registry
./build.sh stable --push
```

## Configuration

### IBC Configuration (`gateway/config.ini`)

Key settings for automation:

```ini
# Authentication
IbLoginId=your_username
IbPassword=your_password

# Trading mode
TradingMode=live  # or 'paper'

# Auto-restart (daily restart at specified time)
AutoRestartTime=02:00 AM

# Session handling
ExistingSessionDetectedAction=primaryoverride
```

### Environment Variables

- `VNC_SERVER_PASSWORD`: Password for VNC access (default: no password)

### Port Mapping

- `4001`: IB Gateway Live Trading API
- `4002`: IB Gateway Paper Trading API
- `5900`: VNC server for GUI access
- `8080`: Health check endpoint

## Debug Tools

Python scripts in `gateway/debug/` help test API connectivity:

```bash
# Install dependencies
pip install -r gateway/debug/requirements.txt

# Test contract details
python gateway/debug/contract_details.py

# Check positions
python gateway/debug/positions.py
```

## Production Deployment

The container image is compatible with AWS ECS and Kubernetes deployments. Use standard container orchestration practices:

- **Memory**: Recommend minimum 2GB, ideally 2-4GB depending on trading volume
- **CPU**: Recommend minimum 1 core (1000m in Kubernetes)
- **Volumes**: Mount `/home/trader/.ibrokerscache` for persistent session data if needed
- **Environment**: Set `VNC_SERVER_PASSWORD` for secure access
- **Ports**: Expose 4001 (live), 4002 (paper), 8080 (health), optionally 5900 (VNC)

## Release Channels

| Channel   | Update Frequency             | Lifespan | Use Case                |
| --------- | ---------------------------- | -------- | ----------------------- |
| `stable`  | Weekly (Sundays at 5:00 UTC) | 12 weeks | Production environments |
| `latest`  | Weekly (Sundays at 5:00 UTC) | 12 weeks | Development/testing     |
| `nightly` | On-demand                    | 1 week   | Experimental features   |

## Architecture Overview

### External Dependencies

The container depends on three external components:

1. **IB Gateway** (Interactive Brokers)
   - Official trading gateway from Interactive Brokers
   - Downloaded from: `https://download2.interactivebrokers.com/installers/ibgateway/{channel}-standalone/`
   - Provides Live and Paper trading APIs

2. **IBC** (Interactive Brokers Controller)
   - Open-source project: [IbcAlpha/IBC on GitHub](https://github.com/IbcAlpha/IBC)
   - Automates gateway startup, login, and configuration
   - Downloaded from GitHub releases during build

3. **Unstoppable** (Hartza Capital)
   - Process supervisor: `quay.io/hartza-capital/unstoppable` (public image)
   - Manages process lifecycle with auto-restart
   - Provides health checks on port `8080`

### Build Process

The container uses a multi-stage build:

- **Build stage**: Downloads IB Gateway installer and IBC from GitHub releases
- **Runtime stage**: Python 3.14 slim base with X11/VNC support and rootless user (`trader`)
- **Entry point**: `unstoppable` service manages IBC startup, X11/VNC server, and health monitoring

## Security Considerations

- **Credentials**: Never hardcode credentials in config files. Use environment variables or secrets management
- **Rootless**: Runs as unprivileged `trader` user (UID 10001) with no root access
- **Network**: Restrict API access to trusted IP addresses only
- **VNC**: Use strong passwords for VNC access and disable if not needed
- **Updates**: Regularly update to latest stable releases for security patches
- **Process supervisor**: Uses public `quay.io/hartza-capital/unstoppable` image (source code is private at Hartza Capital)

## Troubleshooting

### Common Issues

**Gateway won't start:**

- Check credentials in `config.ini`
- Verify trading mode matches account type
- Check IBC logs: `docker exec <container_id> tail -f /home/trader/ibc/logs/ibc.log`
- Verify IBC version compatibility (see CLAUDE.md for version details)
- Check overall logs: `docker logs <container_id>`

**API connection refused:**

- Ensure ports 4001/4002 are exposed and accessible
- Check if gateway is fully initialized (can take 1-2 minutes)
- Verify API is enabled in gateway settings

**VNC connection fails:**

- Check `VNC_SERVER_PASSWORD` environment variable
- Ensure port 5900 is exposed
- Wait for X11 server initialization

### Logs and Debugging

```bash
# View container logs
docker logs ib-gateway-container

# Access container shell
docker exec -it ib-gateway-container bash

# Check IBC logs
docker exec ib-gateway-container tail -f /home/trader/ibc/logs/ibc.log
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with all three channels (`stable`, `latest`, `nightly`)
5. Submit a pull request

## Support

- **Issues**: Report bugs on [GitHub Issues](https://github.com/hartza-capital/docker-ib-gateway/issues)
- **Documentation**: See [IBC Documentation](https://github.com/IbcAlpha/IBC) for advanced configuration
- **Images**: Available on [Quay.io](https://quay.io/repository/hartza-capital/ib-gateway?tab=tags)
