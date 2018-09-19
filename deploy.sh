#!/bin/bash

# Main variables
IP='159.203.80.149'
VERSION=$(awk '/version/{gsub(/("|",)/,"",$2);print $2};' package.json)
HASH=$(git rev-parse head)
TODAY=$(date)
USER=$(whoami)
KEY="/Users/$USER/.ssh/id_rsa"

# Now package and move to server
echo "Creating log..."
{
  echo "site: space-invaders@www.nathanielinman.com";
  echo "date: $TODAY";
  echo "user: $USER";
  echo "hash: $HASH";
  echo "application: space-invaders";
  echo "version: $VERSION";
} > ./server/root/deployDatabase.txt
echo "Packaging files..."
tar --exclude='.*' --exclude='server/' --exclude='node_modules/' --exclude='music/' --exclude='metrics/' -cvf ../plosdb.tar ./* && mv ../plosdb.tar ./
tar -uf ./plosdb.tar ./server/root/deployDatabase.txt
gzip ./plosdb.tar
echo "Moving files to server..."
rsync -avhtz -e "ssh -i $KEY" plosdb.tar.gz nate@$IP:./
echo "Extracting files..."
ssh -i "$KEY" nate@$IP << EOF
  sudo rm /var/www/space-invaders
  sudo mkdir /var/www/space-invaders
  sudo tar -C /var/www/space-invaders -zxvf space-invaders.tar.gz
EOF
echo "Cleaning up deployment files..."
rm ./space-invaders.tar.gz
echo "Verifying successful deploy..."
sleep 5
curl https://nathanielinman.com/deployDatabase.txt
rm -rf ./server/root/*

