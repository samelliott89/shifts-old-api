#!/usr/bin/env bash

echo $'\e[1G'"------> Recieved update, deploying master"

CODE_DIR="/home/josh/www/shifts-api"
FOREVER="./node_modules/.bin/forever"

# Checkout the latest code and move into that dir
echo $'\e[1G'"------> Checking out latest master into $CODE_DIR"
GIT_WORK_TREE=$CODE_DIR git checkout -f | sed $'s/^/\e[1G        /'
cd $CODE_DIR

# Do app-specific build tasks
echo $'\e[1G'"------> Installing NPM dependencies"
npm install | sed $'s/^/\e[1G        /'

echo $'\e[1G'"------> Finally, restarting server"
$FOREVER restart api | sed $'s/^/\e[1G        /'

echo $'\e[1G'"------> Deployed changes to server 👍"