FROM debian:stable-slim AS build

ARG IBC_VERSION=3.12.0

RUN apt update && \
    apt install -y \
    git \
    unzip \ 
    wget

# Download and install offline version of TWS
RUN wget https://download2.interactivebrokers.com/installers/tws/latest-standalone/tws-latest-standalone-linux-x64.sh -O install.sh \
    && chmod +x install.sh

RUN wget https://github.com/IbcAlpha/IBC/releases/download/${IBC_VERSION}/IBCLinux-${IBC_VERSION}.zip -O ibc.zip \
    && unzip ibc.zip -d /opt/ibc

# Set permissions
RUN chmod +x *.sh /opt/ibc/*.sh /opt/ibc/*/*.sh

FROM debian:stable-slim

# procps is needed for twsstart.sh on Debian
RUN apt update && \
    apt install -y \
    nginx \ 
    procps \
    python3 \
    novnc \ 
    x11vnc \
    xterm \
    xvfb \
    net-tools

RUN useradd -m -u 10001 trader

USER trader
WORKDIR /home/trader

COPY  --chown=trader --from=build /install.sh ./install.sh
RUN yes '' | ./install.sh \
    && rm ./install.sh

COPY --chown=trader --from=build /opt/ibc /opt/ibc

COPY --chown=trader config.ini gatewaystart.sh /opt/ibc/
COPY --chown=trader start.sh .
COPY --chown=trader nginx.conf /usr/share/nginx/nginx.conf
RUN chmod +x ./start.sh /opt/ibc/**.sh

CMD [ "./start.sh" ]