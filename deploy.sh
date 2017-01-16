#!/bin/bash

# Passing in your user name is preferred for logging into remote server
# Usage 1: stage.sh <user>
# If you don't pass in your name it will assume server is same as localhost
# Usage 2: stage.sh

# Main variables
SERVERIP="plainsofsedia.com"
VERSION=`awk '/version/{gsub(/("|",)/,"",$2);print $2};' package.json`
GITHASH=`git rev-parse head`
TODAY=$(date)
USER=u68221731

# Make sure user was passed in, if it wasn't capture it - get location of keys
if [ $USER = "" ]; then
  USER=$(whoami)
fi
KEYPATH=$(whoami)
KEY="/Users/$KEYPATH/.ssh/id_rsa"

# Build the application and make a tar of the result including
# an information file that contains last deploy dates and version
echo "npm run production"
npm run production
echo "site: www.spaceinvaders.nathanielinman.com " > dist/deploy.txt
echo "hash: $GITHASH " >> dist/deploy.txt
echo "version: $VERSION " >> dist/deploy.txt
echo "date: $TODAY" >> dist/deploy.txt
cd dist && tar -czvf ../dist.tar.gz . && cd ..

# Put the package onto the staging server
echo "rsynching files User: $USER => Key: $KEY => IP: $SERVERIP"
rsync -avhtz -e "ssh -i $KEY" dist.tar.gz $USER@$SERVERIP:./
echo "releasing files and restarting"
ssh -i $KEY $USER@$SERVERIP "rm -rf SpaceInvaders/*; tar -C SpaceInvaders/ -zxvf dist.tar.gz; rm dist.tar.gz"

# Clean up after yourself
echo "clean up"
rm dist.tar.gz
echo "DONE"

# Display the result of the deploy text to make sure it was successful
curl http://www.spaceinvaders.nathanielinman.com/deploy.txt
