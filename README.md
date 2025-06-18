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
  - **`stable` & `latest`**: Infinite lifespan until replaced by a new version. Previous versions expire 3 months after replacement
  - **`nightly`**: Temporary builds (3-day lifespan) for testing advanced versions
- **Python scripts**: Debugging tools in debug to test API connections
- **Weekly releases**: Automated releases on `stable` and `latest` channels every Sunday
- **Cloud-ready**: Works perfectly on AWS ECS/Kubernetes. Hartza Capital uses a customized version on AWS ECS in production
- **Extensible**: You can add your own custom scripts within the container (though this is generally considered a bad practice, it's the simplest approach given the gateway's security criticality and IBKR gateway's rigidity)

## Project Structure

- **build.sh**: Automated build script that handles different channels
- **docker-compose.yaml**: Configuration to start the container easily
- **Dockerfile**: Container build with IB Gateway and IBC
- **config.ini**: IBC configuration for automation
- **GitHub Actions**: Automated CI/CD to build and publish images to [Quay.io](https://quay.io/repository/hartza-capital/ib-gateway?tab=tags)

## Usage

The project allows running IB Gateway in headless mode for automated trading strategies, with optional VNC access on port 5900 and API on ports 4001/4002.