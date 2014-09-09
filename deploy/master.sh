#!/usr/bin/env bash

echo $'\e[1G' to $'\e[1G\e[K' "Received updates, deploying master"

CODE_DIR="/home/josh/www/shifts-api"
GIT_WORK_TREE=$CODE_DIR

# Checkout the latest code and move into that dir
GIT_WORK_TREE=$CODE_DIR git checkout -f
cd $CODE_DIR

# Do app-specific build tasks
npm install
forever restart api

echo $'\e[1G' to $'\e[1G\e[K' "Deployed changes to server 👍"
echo $'\e[1G'
echo $'\e[1G'
echo $'\e[1G'
echo $'\e[1G'
echo $'\e[1G'"------>" "All done."