#/bin/bash
PUSH=$1
IBC_VERSION=3.12.0
BUILD=$(curl -s https://download2.interactivebrokers.com/installers/ibgateway/latest-standalone/version.json | grep -o '{.*}' | jq -r .buildVersion)

docker build ./gateway -t quay.io/arktos-venture/ibkr-gateway:$BUILD --build-arg IBC_VERSION=$IBC_VERSION --build-arg BUILD=$BUILD --platform linux/amd64
docker tag quay.io/arktos-venture/ibkr-gateway:$BUILD quay.io/arktos-venture/ibkr-gateway:latest
if [ "$PUSH" = "--push" ]; then
    docker push quay.io/arktos-venture/ibkr-gateway:$BUILD
    docker push quay.io/arktos-venture/ibkr-gateway:latest
fi