#/bin/bash

# Inputs values
CHANNEL=$1
PUSH=$2

# Default values
URL_DOWNLOAD=https://download2.interactivebrokers.com/installers/ibgateway/$CHANNEL-standalone/version.json
IMAGE=quay.io/arktos-fund/ibkr-gateway

echo "Try to extract versions"
if [ "$CHANNEL" = "latest" ]; then
    BUILD=$(curl -s $URL_DOWNLOAD | grep -o '{.*}' | jq -r .buildVersion)
    docker build ./gateway --platform linux/amd64 --build-arg CHANNEL=$CHANNEL --build-arg QUAY_EXPIRE=12w -t $IMAGE:$BUILD
elif [ "$CHANNEL" = "stable" ]; then
    BUILD=$(curl -s $URL_DOWNLOAD | grep -o '{.*}' | jq -r .buildVersion)
    docker build ./gateway --platform linux/amd64 --build-arg CHANNEL=$CHANNEL -t $IMAGE:$BUILD
elif [ "$CHANNEL" = "nightly" ]; then
    BUILD=$(git rev-parse --short HEAD)
    docker build ./gateway --platform linux/amd64 --build-arg CHANNEL=stable --build-arg QUAY_EXPIRE=1w -t $IMAGE:$BUILD
else
    echo "channel ${CHANNEL} isn't available"
    exit 1
fi

if [ "$CHANNEL" = "latest" ] || [ "$CHANNEL" = "stable" ]; then
    # Extract versions
    MAJOR=$(echo $BUILD | grep -o '^[0-9]*')
    MINOR=$(echo $BUILD | grep -o '^[0-9]*.[0-9]*')

    # Build & tags
    echo "Tags image $BUILD"
    docker tag $IMAGE:$BUILD $IMAGE:$CHANNEL
    docker tag $IMAGE:$BUILD $IMAGE:$MAJOR-$CHANNEL
    docker tag $IMAGE:$BUILD $IMAGE:$MINOR
fi

# Push images
if [ "$PUSH" = "--push" ]; then
    echo "Push images Gateway" 
    docker push $IMAGE:$BUILD
    if [ "$CHANNEL" = "latest" ] || [ "$CHANNEL" = "stable" ]; then
        docker push $IMAGE:$MINOR
        if [ "$CHANNEL" = "stable" ]; then
            docker push $IMAGE:$MAJOR
        fi
        docker push $IMAGE:$CHANNEL
    fi
fi