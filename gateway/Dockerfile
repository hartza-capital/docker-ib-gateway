FROM debian:stable-slim AS build

ARG CHANNEL=latest
ARG IBC_VERSION=3.16.2

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

FROM debian:stable-slim

ARG QUAY_EXPIRE=never

LABEL maintainer="oss@arktos.fund"
LABEL quay.expires-after=${QUAY_EXPIRE}

RUN apt update && \
    apt install -y x11vnc xvfb procps && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 10001 trader

USER trader
WORKDIR /home/trader

COPY  --chown=trader --from=build /install.sh ./install.sh
RUN yes '' | ./install.sh \
    && rm ./install.sh

COPY --chown=trader --from=build /opt/ibc /opt/ibc
COPY --chown=trader config.ini ./scripts/gatewaystart.sh /opt/ibc/
COPY --chown=trader ./scripts/run.sh .
RUN chmod +x ./*.sh /opt/ibc/**.sh

# 5900: VNC
# 4001: Gateway Live Trading
# 4002: Gateway Virtual Trading
EXPOSE 5900 4001 4002

CMD [ "./run.sh" ]