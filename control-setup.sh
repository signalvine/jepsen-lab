#!/bin/bash
set -e
set -x

# Fix permissions on the private key
chmod 600 ~/.ssh/id_rsa

# Get openjdk8
echo 'deb http://cloudfront.debian.net/debian jessie-backports main' | sudo tee /etc/apt/sources.list.d/backports.list
sudo apt-get update
sudo apt-get install -y openjdk-8-jre openjdk-8-jre-headless git

# Install Leiningen
mkdir -p ~/.bin
wget -O ~/.bin/lein https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod +x ~/.bin/lein
echo "export PATH=~/.bin:$PATH" >> .bashrc
