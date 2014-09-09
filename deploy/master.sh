#!/bin/sh
read OLDID NEWID BRANCH
REF_PREFIX="refs/heads/"
BRANCH=${BRANCH_PATH#${REF_PREFIX}}

echo "Hey cool! This is the checked-in deploy script!"

echo "Received updates, deploying $BRANCH"

GIT_WORK_TREE=/home/josh/www/shifts-api git checkout -f
cd /home/josh/www/shifts-api
npm install
forever restart api
echo "Deployed changes to server 👍"