#!/bin/bash

# Main variables
IP='104.236.105.218'
VERSION=$(awk '/version/{gsub(/("|",)/,"",$2);print $2};' package.json)
HASH=$(git rev-parse head)
TODAY=$(date)
USER=$(whoami)
KEY="/Users/$USER/.ssh/id_rsa"

# Now package and move to server
echo "Cleaning distribution folder..."
rm -rf dist
echo "Compiling production build..."
npm run build
echo "Creating log..."
{
  echo "site: space-invaders@www.nathanielinman.com";
  echo "date: $TODAY";
  echo "user: $USER";
  echo "hash: $HASH";
  echo "application: space-invaders";
  echo "version: $VERSION";
} > ./dist/deploy.txt
echo "Packaging files..."
cd ./dist
tar -czvf ../space-invaders.tar.gz .
cd ../
echo "Moving files to server..."
rsync -avhtz -e "ssh -i $KEY" space-invaders.tar.gz nate@$IP:./
echo "Extracting files..."
ssh -i "$KEY" nate@$IP << EOF
  sudo rm -rf /var/www/space-invaders
  sudo mkdir /var/www/space-invaders
  sudo tar -C /var/www/space-invaders -zxvf space-invaders.tar.gz
EOF
echo "Cleaning up deployment files..."
rm ./space-invaders.tar.gz
echo "Verifying successful deploy..."
sleep 5
curl https://space-invaders.nathanielinman.com/deploy.txt

