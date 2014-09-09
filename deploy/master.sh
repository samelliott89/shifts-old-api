#!/usr/bin/env bash

echo $'\e[1G'"------> Recieved update, deploying master"
echo $'\e[1G\e[K'"Deploying master"

CODE_DIR="/home/josh/www/shifts-api"

# Checkout the latest code and move into that dir
GIT_WORK_TREE=$CODE_DIR git checkout -f | sed $'s/^/\e[1G\e[K/'
cd $CODE_DIR

# Do app-specific build tasks
npm install | sed $'s/^/\e[1G\e[K/'
forever restart api | sed $'s/^/\e[1G\e[K/'

echo $'\e[1G'"------> Deployed changes to server 👍"