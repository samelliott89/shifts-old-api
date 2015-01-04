#!/bin/sh
source ./deploy/circleci/predeploy.sh
export ENV_NAME="shiftsapi-prod"
source ./deploy/circleci/deploy.sh
