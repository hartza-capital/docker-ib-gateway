# IBKR Gateway in Container

![Latest](https://github.com/arktos-fund/docker-ibkr-gateway/actions/workflows/build_latest.yml/badge.svg?branch=master)
![Stable](https://github.com/arktos-fund/docker-ibkr-gateway/actions/workflows/build_stable.yml/badge.svg?branch=master)

The base of project is based on [extrange/ibkr-docker](https://github.com/extrange/ibkr-docker), but the goal/method is different.   
**Arktos Fund** isn't affiliated to **Interactive Brokers**.

## Features

- **Fully containerized** IBKR Gateway instance + [IBC Alpha](https://github.com/IbcAlpha) with no external dependencies,
- **Autorestarts automatically** (for example, due to daily logoff),
- **Supports VNC**,
- **Helm chart** for Kubernetes.

## Getting Started

- Build the image:
  - `./build.sh {stable||latest}`
- Start the container:
  - `docker-compose up -d`
  - start VNC Client (url: `127.0.0.1:5900`, password `test`)
- To stop: `docker-compose down`

See [KUBERNETES.md](KUBERNETES.md) to execute IB Gateway in Kubernetes.

## Paper vs Live Account

This container is setup to connect to a paper account. To switch to a live account:

- Create your config IBC (example `gateway/config/config.ini.example`) in the same folder of example `config.ini`.
  - `TradingMode=live`
  - `IbLoginId=LOGIN`
  - `IbPassword=XXXX`

You will have to restart the container after making these changes.

## Changes from the default config.ini

```config
AcceptBidAskLastSizeDisplayUpdateNotification=accept
AcceptIncomingConnectionAction=accept
AcceptNonBrokerageAccountWarning=yes
TradingMode=paper
```
