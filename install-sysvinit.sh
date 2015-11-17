#!/bin/bash
set -e
set -x

sudo apt-get update
sudo DEBIAN_FRONTENT=noninteractive apt-get install -y sysvinit-core sysvinit sysvinit-utils systemd-shim
sudo cp /usr/share/sysvinit/inittab /etc/inittab
sudo reboot
