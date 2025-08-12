FROM debian:stable-slim AS build

ARG CHANNEL=latest
ARG BUILD
ENV IB_GATEWAY_RELEASE_CHANNEL=$CHANNEL
ENV IB_GATEWAY_VERSION=$BUILD
ENV IBC_VERSION=3.21.2

RUN apt update && \
    apt install -y \
    unzip \ 
    wget

RUN wget https://download2.interactivebrokers.com/installers/ibgateway/${CHANNEL}-standalone/ibgateway-${CHANNEL}-standalone-linux-x64.sh -O install.sh \
    && chmod +x install.sh

    RUN wget https://github.com/IbcAlpha/IBC/releases/download/${IBC_VERSION}/IBCLinux-${IBC_VERSION}.zip -O ibc.zip \
    && unzip ibc.zip -d /opt/ibc

# Set permissions
RUN chmod +x *.sh /opt/ibc/*.sh /opt/ibc/*/*.sh

# Python base for running custom scripts
FROM python:3.13-slim-bookworm

LABEL org.opencontainers.image.source=https://github.com/hartza-capital/ib-gateway-docker
LABEL org.opencontainers.image.url=https://quay.io/repository/hartza-capital/ib-gateway
LABEL org.opencontainers.image.description="Docker image with IB Gateway and IBC "
LABEL org.opencontainers.image.version=${IB_GATEWAY_VERSION}-${IB_GATEWAY_RELEASE_CHANNEL}

ARG QUAY_EXPIRE=never

LABEL maintainer="oss@hartza.capital"
LABEL quay.expires-after=${QUAY_EXPIRE}

# Install dependencies
RUN apt update && \
    apt install -y x11vnc xvfb procps && \
    rm -rf /var/lib/apt/lists/*

# Copy unstoppable/healthcheck binary
COPY --from=quay.io/hartza-capital/unstoppable:latest /usr/local/bin/unstoppable /usr/local/bin/unstoppable
COPY --from=quay.io/hartza-capital/unstoppable:latest /usr/local/bin/healthcheck /usr/local/bin/healthcheck

# Create rootless user
RUN useradd -m -u 10001 trader

USER trader
WORKDIR /home/trader

# Create logs directory with trader user
RUN mkdir -p /home/trader/ibc/logs

# Install IB Gateway
COPY  --chown=trader --from=build /install.sh ./install.sh
RUN yes '' | ./install.sh \
    && rm ./install.sh

# Copy IBC and scripts
COPY --chown=trader --from=build /opt/ibc /opt/ibc
COPY --chown=trader config.ini ./scripts/gatewaystart.sh /opt/ibc/
COPY --chown=trader ./scripts/x11vnc.sh x11vnc.sh
COPY --chown=trader unstoppable.conf unstoppable.conf
RUN chmod +x ./*.sh /opt/ibc/**.sh

# 5900: VNC
# 4001: Gateway Live Trading
# 4002: Gateway Virtual Trading
# 8080: Unstoppable Healthcheck
EXPOSE 5900 4001 4002 8080

CMD [ "unstoppable", "-c", "unstoppable.conf" ]
