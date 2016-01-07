#!/usr/bin/env bash

# Gather command line options
for i in "$@"
do 
  case $i in 
    -skiptests|--skip-tests) # Skip tests portion of the build
    SKIPTESTS=YES
    shift
    ;;
    -d=*|--build-dir=*) # Specify the directory to use for the build
    BUILDDIR="${i#*=}"
    shift
    ;;
    -skipinstall|--skip-install) # Skip dbkg install
    SKIPINSTALL=YES
    ;;
    *)
    #TODO Maybe define a help section?
    ;;
  esac
done

if [[ $BUILDDIR && -d $BUILDDIR ]]; then
  :
else 
  BUILDDIR="/tmp/source-git"
  rm -rf "${BUILDDIR}" # Clear out all previous attempts
  mkdir -p "${BUILDDIR}" 
fi

echo "BUILD DIRECTORY USED: ${BUILDDIR}" 
cd "${BUILDDIR}"

# Get the dependencies for git, then get openssl
sudo apt-get install build-essential fakeroot dpkg-dev -y
sudo apt-get build-dep git -y
sudo apt-get install libcurl4-openssl-dev -y
if ! grep -q "git-core" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
  sudo apt-add-repository ppa:git-core/ppa
else
  echo "git-core already in ppa"
fi
apt-get source git

# We need to actually go into the git source directory
# find -type f -name "*.dsc" -exec dpkg-source -x \{\} \;
cd $(find -mindepth 1 -maxdepth 1 -type d -name "git-*")
pwd

# This is where we actually change the library from one type to the other.
sed -i -- 's/libcurl4-gnutls-dev/libcurl4-openssl-dev/' ./debian/control
# Compile time, itself, is long. Skips the tests. Do so at your own peril.
#sed -i -- '/TEST\s*=\s*test/d' ./debian/rules
if [[ $SKIPTESTS == "YES" ]]
then
  sed -i -- '/TEST\s*=\s*test/d' ./debian/rules
fi

# Build it.
dpkg-buildpackage -rfakeroot -b

# Install
if [[ -z $SKIPINSTALL ]]
then 
  find .. -type f -name "git_*ubuntu*.deb" -exec sudo dpkg -i \{\} \;
fi
