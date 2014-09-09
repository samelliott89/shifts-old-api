#!/usr/bin/env bash

# Some heads up:
#  - We redirect all stderr to stdin with 2>&1 to make sure...
#  - Each command ends with 'sed' to prevent 'remove: ' from showing in the console
#    when this is ran as a git remote hook
#  - All echos also start with the escape sequence for this same reason

echo $'\e[1G'"------> Recieved update, deploying master"

CODE_DIR="/home/josh/www/shifts-api"
FOREVER="./node_modules/.bin/forever"

# Checkout the latest code and move into that dir
echo $'\e[1G'"------> Checking out latest master into $CODE_DIR"
GIT_WORK_TREE=$CODE_DIR git checkout -f 2>&1 | sed $'s/^/\e[1G        /'
cd $CODE_DIR

# Do app-specific build tasks
echo $'\e[1G'"------> Installing NPM dependencies"
npm install 2>&1 | sed $'s/^/\e[1G        /'

echo $'\e[1G'"------> Finally, restarting server"
$FOREVER restart api 2>&1 | sed $'s/^/\e[1G        /'

echo $'\e[1G'"------> Deployed changes to server 👍"