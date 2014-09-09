#!/bin/sh
echo "Received updates, deploying master to production"

GIT_WORK_TREE=/home/josh/www/shifts-api git checkout -f
cd /home/josh/www/shifts-api
npm install
forever restart api
echo "Deployed changes to server 👍"