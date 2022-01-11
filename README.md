# IBKR Gateway in Docker

## Features

- **Fully containerized** IBKR Gateway instance + [IBC Alpha](https://github.com/IbcAlpha) in Docker, no external dependencies
- **Supports noVNC** (a browser-based VNC client, proxied via Websockify)
- **Autorestarts TWS automatically** (for example, due to daily logoff)

## Getting Started

- Install [Docker](https://docs.docker.com/get-docker/)
- Build the image:
  - `./build.sh`
- Start the container:
  - `docker-compose up -d`
  - TWS API is available on port `5000` by default
  - You can view the noVNC client at [localhost:6080/vnc.html](http://localhost:6080/vnc.html)
- To stop: `docker-compose down`

## Paper vs Live Account

This container is setup to connect to a paper account. To switch to a live account:

- Modify proxy.yaml's `destination` accordingly:
  - Live Account: `4001`
  - Paper Account: `4002`
- Modify `gateway/config/ibc.ini`:
  - `TradingMode=live`

You will have to restart the container after making these changes.

## TWS Version Changes

TWS is updated frequently. Whenever the major version is incremented, you need to reconfigure the script.

Modify the value of `TWS_MAJOR_VRSN` in `docker-compose.yml` to the latest version number without periods/alphabets (i.e. 10.11e -> 1011)

## Changes from the default config.ini

```config
AcceptBidAskLastSizeDisplayUpdateNotification=accept
AcceptIncomingConnectionAction=accept
AcceptNonBrokerageAccountWarning=yes
TradingMode=paper
```
