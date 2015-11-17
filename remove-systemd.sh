#!/bin/bash
set -e
set -x

sudo apt-get remove -y --purge --auto-remove systemd
echo -e 'Package: systemd\nPin: origin ""\nPin-Priority: -1' | sudo tee /etc/apt/preferences.d/systemd
echo -e '\n\nPackage: *systemd*\nPin: origin ""\nPin-Priority: -1' | sudo tee -a /etc/apt/preferences.d/systemd
