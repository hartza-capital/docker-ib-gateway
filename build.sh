#!/usr/bin/env bash
set -euo pipefail

# Inputs values
CHANNEL=${1:-}
PUSH=${2:-}

if [ -z "$CHANNEL" ]; then
    echo "usage: $0 <stable|latest> [--push]" >&2
    exit 1
fi

# Default values
URL_DOWNLOAD="https://download2.interactivebrokers.com/installers/ibgateway/${CHANNEL}-standalone/version.json"
IMAGE=quay.io/hartza-capital/ib-gateway

echo "Try to extract versions"
if [ "$CHANNEL" != "latest" ] && [ "$CHANNEL" != "stable" ]; then
    echo "channel ${CHANNEL} isn't available" >&2
    exit 1
fi

BUILD=$(curl -s "$URL_DOWNLOAD" | grep -o '{.*}' | jq -r .buildVersion)
if [ -z "$BUILD" ] || [ "$BUILD" = "null" ]; then
    echo "unable to resolve the Gateway build version from ${URL_DOWNLOAD}" >&2
    exit 1
fi

BUILD_ARGS=(--build-arg "BUILD=${BUILD}" --build-arg "CHANNEL=${CHANNEL}")
if [ "$CHANNEL" = "latest" ]; then
    BUILD_ARGS+=(--build-arg QUAY_EXPIRE=12w)
fi

docker build ./gateway --platform linux/amd64 "${BUILD_ARGS[@]}" -t "$IMAGE:$BUILD"

# Extract versions
MAJOR=$(echo "$BUILD" | grep -o '^[0-9]*')
MINOR=$(echo "$BUILD" | grep -o '^[0-9]*.[0-9]*')

# Build & tags
echo "Tags image $BUILD"
docker tag "$IMAGE:$BUILD" "$IMAGE:$CHANNEL"
docker tag "$IMAGE:$BUILD" "$IMAGE:$MAJOR-$CHANNEL"
docker tag "$IMAGE:$BUILD" "$IMAGE:$MINOR"

# Push images
if [ "$PUSH" = "--push" ]; then
    echo "Push images Gateway"
    docker push "$IMAGE:$BUILD"
    docker push "$IMAGE:$MINOR"
    if [ "$CHANNEL" = "stable" ]; then
        docker push "$IMAGE:$MAJOR"
    fi
    docker push "$IMAGE:$CHANNEL"
fi
