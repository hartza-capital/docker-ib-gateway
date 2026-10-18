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

# The minor series (10.50) and the build version pin a release; the channel tag
# is the only tag that jumps between minors. PUBLISHED_TAGS drives the push loop,
# so nothing is pushed unless it was created.
echo "Tags image $BUILD"
MINOR=$(echo "$BUILD" | cut -d. -f1-2)
PUBLISHED_TAGS=("$BUILD" "$MINOR" "$CHANNEL")
docker tag "$IMAGE:$BUILD" "$IMAGE:$MINOR"
docker tag "$IMAGE:$BUILD" "$IMAGE:$CHANNEL"

# Version tags first, channel last: a failed version push leaves stable/latest alone.
if [ "$PUSH" = "--push" ]; then
    echo "Push images Gateway"
    for tag in "${PUBLISHED_TAGS[@]}"; do
        docker push "$IMAGE:$tag"
    done
fi
