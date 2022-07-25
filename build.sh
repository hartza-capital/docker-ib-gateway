#/bin/bash
PUSH=$1
IBC_VERSION=3.14.0

echo "Extract versions"
BUILD=$(curl -s https://download2.interactivebrokers.com/installers/ibgateway/latest-standalone/version.json | grep -o '{.*}' | jq -r .buildVersion)
MAJOR=$(echo $BUILD | grep -o '^[0-9]*')
MINOR=$(echo $BUILD | grep -o '^[0-9]*.[0-9]*')
IMAGE=quay.io/arktos-venture/ibkr-gateway

echo "Build images $BUILD"
docker build ./gateway --platform linux/amd64 --build-arg IBC_VERSION=$IBC_VERSION -t $IMAGE:$BUILD
docker tag $IMAGE:$BUILD $IMAGE:latest
docker tag $IMAGE:$BUILD $IMAGE:$MAJOR
docker tag $IMAGE:$BUILD $IMAGE:$MINOR
if [ "$PUSH" = "--push" ]; then
    echo "Push images" 
    docker push $IMAGE:$BUILD
    docker push $IMAGE:$MAJOR
    docker push $IMAGE:$MINOR
    docker push $IMAGE:latest
fi