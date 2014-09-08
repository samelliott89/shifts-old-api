#!/bin/sh
read OLDID NEWID BRANCH
echo "Received updates, deploying"

echo Old ID: $OLDID
echo New ID: $NEWID
echo Branch: $BRANCH

GIT_WORK_TREE=/home/josh/www/shifts-api git checkout -f
cd /home/josh/www/shifts-api
npm install
forever restart api
echo "Deployed changes to server 👍"