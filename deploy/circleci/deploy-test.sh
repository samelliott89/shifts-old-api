#!/bin/sh
source ./deploy/circleci/predeploy.sh
export ENV_NAME="shiftsapi-test"
source ./deploy/circleci/deploy.sh
