#!/bin/bash
# 
# usage: ./1_deploy-container [local|push|test]
set -eu

#DOCKERHUB_USER=${DOCKERHUB_USER:-local}
DOCKER=${DOCKER:-sudo docker}
ECR="$1"

# Container Version
#VERSION=0 # Dev version
VERSION=0.0.1

# DOCKERHUB_USER='serratusbio'
# sudo docker login
$DOCKER build \
  -t steck -t steck:latest \
  -t steck:$VERSION .

# Push to ECR
if [ $ECR == 'push' ]
then
  echo "Push to ECR"
  # Push to ECR (credentials implicit)
  $DOCKER tag steck:latest public.ecr.aws/q4q7t4w2/steck:latest

  # Get AWS credentials
  aws ecr-public get-login-password --region us-east-1 \
      | sudo docker login --username AWS \
        --password-stdin public.ecr.aws/q4q7t4w2

  $DOCKER push public.ecr.aws/q4q7t4w2/steck:latest
fi

# Run unit-test
# TBD
$DOCKER run steck

#!/bin/bash
set -e
ACCOUNT=$(aws sts get-caller-identity --query Account --output text) # AWS ACCOUNT ID
DOCKER_CONTAINER=logan-analysis-job-$(uname -m)
REPO=${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com/${DOCKER_CONTAINER}
TAG=build-$(date -u "+%Y-%m-%d")
echo "Building Docker Image..."
#NOCACHE=--no-cache
docker build $NOCACHE -t $DOCKER_CONTAINER .

#echo "Authenticating against AWS ECR..."
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${ACCOUNT}.dkr.ecr.us-east-1.amazonaws.com
# create repository (only needed the first time)
aws ecr create-repository --repository-name $DOCKER_CONTAINER ||true
echo "Tagging ${REPO}..."
docker tag $DOCKER_CONTAINER:latest $REPO:$TAG
docker tag $DOCKER_CONTAINER:latest $REPO:latest
echo "Deploying to AWS ECR"
docker push $REPO
