#!/bin/sh

echo "Received updates, deploying master"

CODE_DIR="/home/josh/www/shifts-api"
GIT_WORK_TREE=$CODE_DIR

# Checkout the latest code and move into that dir
GIT_WORK_TREE=$CODE_DIR git checkout -f
cd $CODE_DIR

# Do app-specific build tasks
npm install
forever restart api

echo "Deployed changes to server 👍"