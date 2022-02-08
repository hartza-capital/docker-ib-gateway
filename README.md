# IBKR Gateway in Container

## Features

- **Fully containerized** IBKR Gateway instance + [IBC Alpha](https://github.com/IbcAlpha) with no external dependencies,
- **Supports noVNC** (a browser-based VNC client, proxied via Websockify),
- **Autorestarts automatically** (for example, due to daily logoff),
- **Helm chart** for Kubernetes.

## Getting Started

- Build the image:
  - `./build.sh`
- Start the container:
  - `docker-compose up -d`
  - TWS API is available on port `5000` by default
  - You can view the noVNC client at [localhost:6080/vnc.html](http://localhost:6080/vnc.html)
- To stop: `docker-compose down`

See [KUBERNETES.md](KUBERNETES.md) to execute IB Gateway in Kubernetes.

## Paper vs Live Account

This container is setup to connect to a paper account. To switch to a live account:

- Create your config IBC (example `gateway/config/config.ini.example`) in the same folder of example `config.ini`.
  - `TradingMode=live`
  - `IbLoginId=LOGIN`
  - `IbPassword=XXXX`
- Modify `gateway/config/proxy.yaml`, with the live or paper port:
  - `address: 127.0.0.1:4001`

You will have to restart the container after making these changes.

## Changes from the default config.ini

```config
AcceptBidAskLastSizeDisplayUpdateNotification=accept
AcceptIncomingConnectionAction=accept
AcceptNonBrokerageAccountWarning=yes
TradingMode=paper
```
