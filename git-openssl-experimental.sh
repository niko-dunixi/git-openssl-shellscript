#!/usr/bin/env bash

# Get the dependencies for git, then get openssl
#sudo apt-get install build-essential fakeroot dpkg-dev -y
#sudo apt-get build-dep git -y
#sudo apt-get install libcurl4-openssl-dev -y
sudo apt-get install build-essential dpkg-dev checkinstall -y
sudo apt-get install libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev -y
sudo apt-get install asciidoc xmlto docbook2x -y

if [ -d "./git" ]; then
  cd ./git
  git pull origin master
else
  git clone http://git.kernel.org/pub/scm/git/git.git
  cd ./git
fi

# This is where we actually change the library from one type to the other.
#sed -i -- 's/libcurl4-gnutls-dev/libcurl4-openssl-dev/' ./debian/control
# Compile time, itself, is long. Skips the tests. Do so at your own peril.
#sed -i -- '/TEST\s*=\s*test/d' ./debian/rules

make configure
./configure --prefix=/usr
make all doc info
sudo checkinstall make install install-doc install-html install-info
