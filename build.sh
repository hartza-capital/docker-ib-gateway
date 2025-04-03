#/bin/bash

# Inputs values
CHANNEL=$1
PUSH=$2

# IBC versions stable
IBC_RELEASE_STABLE="3.21.2"
IBC_VERSION_STABLE=$(echo "${IBC_RELEASE_STABLE}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

# IBC versions latest
IBC_RELEASE_LATEST="3.21.2"
IBC_VERSION_LATEST=$(echo "${IBC_RELEASE_LATEST}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

# Default values
URL_DOWNLOAD=https://download2.interactivebrokers.com/installers/ibgateway/$CHANNEL-standalone/version.json
IMAGE=quay.io/hartza-capital/ib-gateway

echo "Try to extract versions"
if [ "$CHANNEL" = "latest" ]; then
    BUILD=$(curl -s $URL_DOWNLOAD | grep -o '{.*}' | jq -r .buildVersion)
    docker build ./gateway --platform linux/amd64 --build-arg BUILD=$BUILD --build-arg CHANNEL=$CHANNEL --build-arg IBC_RELEASE=$IBC_RELEASE_LATEST --build-arg IBC_VERSION=$IBC_VERSION_LATEST --build-arg QUAY_EXPIRE=12w -t $IMAGE:$BUILD
elif [ "$CHANNEL" = "stable" ]; then
    BUILD=$(curl -s $URL_DOWNLOAD | grep -o '{.*}' | jq -r .buildVersion)
    docker build ./gateway --platform linux/amd64 --build-arg BUILD=$BUILD --build-arg CHANNEL=$CHANNEL --build-arg IBC_RELEASE=$IBC_RELEASE_STABLE --build-arg IBC_VERSION=$IBC_VERSION_STABLE -t $IMAGE:$BUILD
elif [ "$CHANNEL" = "nightly" ]; then
    BUILD=$(git rev-parse --short HEAD)
    docker build ./gateway --platform linux/amd64 --build-arg BUILD=$BUILD --build-arg CHANNEL=stable --build-arg IBC_RELEASE=$IBC_RELEASE_LATEST --build-arg IBC_VERSION=$IBC_VERSION_LATEST --build-arg QUAY_EXPIRE=1w -t $IMAGE:$BUILD
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
