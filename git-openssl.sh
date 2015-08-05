#!/usr/bin/env bash

sudo apt-get install build-essential fakeroot dpkg-dev libcurl4-openssl-dev -y
sudo apt-get build-dep git
mkdir -p "${HOME}/source-git/"
cd "${HOME}/source-git/"
apt-get source git

