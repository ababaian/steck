#!/bin/bash
# 
# usage: ./build_containers.sh [local|push]
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
  -t logan -t logan:latest \
  -t logan:$VERSION .

# Push to ECR
if [ $ECR == 'push' ]
then
  echo "Push to ECR"
  # Push to ECR (credentials implicit)
  $DOCKER tag logan:latest public.ecr.aws/q4q7t4w2/logan:latest

  # Get AWS credentials
  aws ecr-public get-login-password --region us-east-1 \
      | sudo docker login --username AWS \
        --password-stdin public.ecr.aws/q4q7t4w2

  $DOCKER push public.ecr.aws/q4q7t4w2/logan:latest
fi

# Run unit-test
$DOCKER run logan