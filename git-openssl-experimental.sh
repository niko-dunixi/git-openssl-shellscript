#!/usr/bin/env bash

# Places us in the somewhat awkward position of needing git, to get git.
# In my opinion, it does work better than building from distributed source
# because there is no need to modify files, just build and install.

# Get the dependencies for git, then get openssl
sudo apt-get install build-essential dpkg-dev checkinstall auto-apt -y
sudo apt-get install libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev -y
sudo apt-get install asciidoc xmlto docbook2x -y

if [ -d "./git" ]; then
  cd ./git
  git pull origin master
else
  git clone http://git.kernel.org/pub/scm/git/git.git
  cd ./git
fi

sudo apt-get remove git -y
sudo apt-get autoremove -y

make configure
auto-apt run ./configure --prefix=/usr
make all doc info
echo "#define VERSION \"9:9.9.9-9${USER}0.9\"" >> config.log
# Builds a package for easy uninstallation. Don't use this
# for building distribution packages. Purely for local builds.
sudo checkinstall make install install-doc install-html install-info
