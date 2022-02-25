#/bin/bash
PUSH=$1
IBC_VERSION=3.12.0

echo "Extract versions"
BUILD=$(curl -s https://download2.interactivebrokers.com/installers/ibgateway/latest-standalone/version.json | grep -o '{.*}' | jq -r .buildVersion)
MAJOR=$(echo $BUILD | grep -o '^[0-9]*')
MINOR=$(echo $BUILD | grep -o '^[0-9]*.[0-9]*')

echo "Build images $BUILD"
docker build ./gateway -t quay.io/arktos-venture/ibkr-gateway:$BUILD --build-arg IBC_VERSION=$IBC_VERSION --platform linux/amd64
docker tag quay.io/arktos-venture/ibkr-gateway:$BUILD quay.io/arktos-venture/ibkr-gateway:latest
docker tag quay.io/arktos-venture/ibkr-gateway:$BUILD quay.io/arktos-venture/ibkr-gateway:$MAJOR
docker tag quay.io/arktos-venture/ibkr-gateway:$BUILD quay.io/arktos-venture/ibkr-gateway:$MINOR
if [ "$PUSH" = "--push" ]; then
    echo "Push images" 
    docker push quay.io/arktos-venture/ibkr-gateway:$BUILD
    docker push quay.io/arktos-venture/ibkr-gateway:$MAJOR
    docker push quay.io/arktos-venture/ibkr-gateway:$MINOR
    docker push quay.io/arktos-venture/ibkr-gateway:latest
fi