#/bin/bash

# Inputs values
CHANNEL=$1
PUSH=$2

# Default values
URL_DOWNLOAD=https://download2.interactivebrokers.com/installers/ibgateway
IBC_VERSION=3.15.2
IMAGE=quay.io/arktos-fund/ibkr-gateway

echo "Try to extract versions"
if [ "$CHANNEL" = "latest" ]; then
    BUILD=$(curl -s $URL_DOWNLOAD/latest-standalone/version.json | grep -o '{.*}' | jq -r .buildVersion)
elif [ "$CHANNEL" = "stable" ]; then
    BUILD=$(curl -s $URL_DOWNLOAD/stable-standalone/version.json | grep -o '{.*}' | jq -r .buildVersion)
    IBC_VERSION=3.12.0
else
    echo "channel ${CHANNEL} isn't available"
    exit 1
fi

# Extract versions
MAJOR=$(echo $BUILD | grep -o '^[0-9]*')
MINOR=$(echo $BUILD | grep -o '^[0-9]*.[0-9]*')

# Build & tags
echo "Build image $BUILD"
docker build ./gateway --platform linux/amd64 --build-arg CHANNEL=$CHANNEL --build-arg IBC_VERSION=$IBC_VERSION -t $IMAGE:$BUILD
docker tag $IMAGE:$BUILD $IMAGE:$CHANNEL
docker tag $IMAGE:$BUILD $IMAGE:$MAJOR
docker tag $IMAGE:$BUILD $IMAGE:$MINOR

# Push images
if [ "$PUSH" = "--push" ]; then
    echo "Push images Gateway" 
    docker push $IMAGE:$BUILD
    docker push $IMAGE:$MINOR
    docker push $IMAGE:$CHANNEL
fi