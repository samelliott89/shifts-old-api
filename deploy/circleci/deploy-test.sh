#!/bin/sh
source ./deploy/circleci/predeploy.sh
export ENV_NAME="test-api"
source ./deploy/circleci/deploy.sh
