#!/usr/bin/env bash

# Clear out all previous attempts
rm -rf "/tmp/source-git/"

# Get the dependencies for git, then get openssl
sudo apt-get install build-essential fakeroot dpkg-dev -y
sudo apt-get build-dep git -y
sudo apt-get install libcurl4-openssl-dev -y
mkdir -p "/tmp/source-git/"
cd "/tmp/source-git/"
sudo apt-add-repository ppa:git-core/ppa
apt-get source git

# We need to actually go into the git source directory
# find -type f -name "*.dsc" -exec dpkg-source -x \{\} \;
cd $(find -mindepth 1 -maxdepth 1 -type d -name "git-*")
pwd

# This is where we actually change the library from one type to the other.
sed -i -- 's/libcurl4-gnutls-dev/libcurl4-openssl-dev/' ./debian/control
# Compile time, itself, is long. Skips the tests. Do so at your own peril.
#sed -i -- '/TEST\s*=\s*test/d' ./debian/rules

# Build it.
dpkg-buildpackage -rfakeroot -b

# Install
find .. -type f -name "git_*ubuntu*.deb" -exec sudo dpkg -i \{\} \;
