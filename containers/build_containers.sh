#!/bin/bash
set -eu
# Build and push container images in parallel.
images=${@:-dl align merge scheduler grafana prometheus scheduler-postgres-exporter}

DOCKERHUB_USER=${DOCKERHUB_USER:-local}
DOCKER_BUILD=${DOCKER_BUILD:-sudo docker}

# Container Version
#VERSION=0 # Dev version
VERSION=0.0.1

# DOCKERHUB_USER='serratusbio'
# sudo docker login

$DOCKER_BUILD build -f Dockerfile \
  -t logan-base -t logan-base:latest \
  -t logan-base:$VERSION .

for img in $images; do
    (
        $DOCKER_BUILD build -f "logan-$img/Dockerfile" \
          -t logan-$img \
          -t $DOCKERHUB_USER/logan-$img \
          -t $DOCKERHUB_USER/logan-$img:$VERSION \
          -t $DOCKERHUB_USER/logan-$img:latest .

        if [ "$DOCKERHUB_USER" == "local" ]; then
          echo "No DOCKERHUB_USER set. Images are local only"
        else 
        # Push container images to repo
          $DOCKER_BUILD push $DOCKERHUB_USER/logan-$img
          echo "Done pushing logan-$img on $DOCKERHUB_USER"
        fi
    ) &
done

wait
