FROM debian:stable-slim AS build

ARG IBC_VERSION

RUN apt update && \
    apt install -y \
    git \
    unzip \ 
    wget

RUN wget https://download2.interactivebrokers.com/installers/ibgateway/latest-standalone/ibgateway-latest-standalone-linux-x64.sh -O install.sh \
    && chmod +x install.sh

RUN wget https://github.com/IbcAlpha/IBC/releases/download/${IBC_VERSION}/IBCLinux-${IBC_VERSION}.zip -O ibc.zip \
    && unzip ibc.zip -d /opt/ibc

# Set permissions
RUN chmod +x *.sh /opt/ibc/*.sh /opt/ibc/*/*.sh

FROM debian:stable-slim

# procps is needed for twsstart.sh on Debian
RUN apt update && \
    apt install -y \
    x11vnc \
    xvfb

RUN useradd -m -u 10001 trader

USER trader
WORKDIR /home/trader

COPY  --chown=trader --from=build /install.sh ./install.sh
RUN yes '' | ./install.sh \
    && rm ./install.sh

COPY --chown=trader --from=build /opt/ibc /opt/ibc

COPY --chown=trader config/config.ini ./scripts/gatewaystart.sh /opt/ibc/
COPY --chown=trader ./scripts/run.sh .
COPY --chown=trader ./scripts/fork_ports_delayed.sh .

COPY --from=quay.io/arktos-venture/tcp-forward:0.0.4 /go ./proxy
COPY config/proxy.yaml ./config.yaml

RUN chmod +x ./*.sh /opt/ibc/**.sh

# 3000: noVNC (0.0.0.0)
# 5000: TCP Tunnel (0.0.0.0)
# 4001: Gateway Live Trading (127.0.0.1)
# 4002: Gateway Virtual Trading (127.0.0.1)
EXPOSE 5000 5900 4001 4002

CMD [ "./run.sh" ]