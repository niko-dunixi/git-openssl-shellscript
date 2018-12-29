#!/usr/bin/env bash
set -e

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
    -skipinstall|--skip-install) # Skip dpkg install
    SKIPINSTALL=YES
    ;;
    *)
    #TODO Maybe define a help section?
    ;;
  esac
done

# Use the specified build directory, or create a unique temporary directory
BUILDDIR=${BUILDDIR:-$(mktemp -d)}

echo "BUILD DIRECTORY USED: ${BUILDDIR}" 
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"

apt update
apt install curl -y

git_tarball_url="https://www.github.com$(curl 'https://github.com/git/git/tags' | grep -o "/git/git/archive/v2\..*\.tar\.gz" | sort -r | head -1 | tr -d '\n')"
echo "DOWNLOADING FROM: ${git_tarball_url}"
curl -L --retry 5 "${git_tarball_url}" --output "git-source.tar.gz"
tar -xf "git-source.tar.gz" --strip 1

# Source dependencies
# Don't use gnutls, this is the problem package.
sudo apt remove --purge libcurl4-gnutls-dev || true
# Using apt-get for these commands, they're not supported with the apt alias on 14.04 (but they may be on later systems)
sudo apt-get autoremove -y
sudo apt-get autoclean
# Meta-things for building on the end-user's machine
sudo apt install build-essential autoconf dh-autoreconf -y
# Things for the git itself
sudo apt install libcurl4-openssl-dev tcl-dev gettext asciidoc -y
sudo apt install libexpat1-dev libz-dev -y
# # This is where we actually change the library from one type to the other.
# # sed -i -- 's/libcurl4-gnutls-dev/libcurl4-openssl-dev/' ./debian/control
# # Compile time, itself, is long. Skips the tests. Do so at your own peril.
# #sed -i -- '/TEST\s*=\s*test/d' ./debian/rules
# if [[ $SKIPTESTS == "YES" ]]
# then
#   sed -i -- '/TEST\s*=\s*test/d' ./debian/rules
# fi


# Build it!
make configure
# Set the prefix based on this decision tree: https://i.stack.imgur.com/BlpRb.png
# Not OS related, Is Software, Not From Package Manager, Has Dependencies, and Built From Source => /usr
./configure --prefix=/usr --with-ssl
make all #doc info

# Install
if [[ -z $SKIPINSTALL ]]
then 
  make install #install-doc install-html install-info
fi

# # Update and add depencencies
# # sudo apt update
# # sudo apt install software-properties-common dpkg-dev build-essential -y
# # # Add the ppa for the most recent git
# # if ! grep -q "git-core" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
# #   sudo add-apt-repository ppa:git-core/ppa --yes
# # else
# #   echo "git-core already in ppa"
# # fi
# # Download some more dependencies because dpgk complains:
# # dpkg-checkbuilddeps: Unmet build dependencies: libpcre3-dev gettext libexpat1-dev subversion libsvn-perl libyaml-perl tcl libhttp-date-perl | libtime-modules-perl bzr python python-bzrlib cvs cvsps libdbd-sqlite3-perl unzip libio-pty-perl asciidoc xmlto docbook-xsl
# # Install openssl development libraries
# sudo apt install libcurl4-openssl-dev -y

# # Get the source for git
# cd "$(mktemp -d)"
# apt-get source git
# cd $(find -mindepth 1 -maxdepth 1 -type d -name "git-*")
# pwd

# # This is where we actually change the library from one type to the other.
# sed -i -- 's/libcurl4-gnutls-dev/libcurl4-openssl-dev/' ./debian/control
# # Compile time, itself, is long. Skips the tests. Do so at your own peril.
# #sed -i -- '/TEST\s*=\s*test/d' ./debian/rules
# if [[ $SKIPTESTS == "YES" ]]
# then
#   sed -i -- '/TEST\s*=\s*test/d' ./debian/rules
# fi

# # Build it.
# dpkg-buildpackage -rfakeroot -b

# # Install
# if [[ -z $SKIPINSTALL ]]
# then 
#   find .. -type f -name "git_*ubuntu*.deb" -exec sudo dpkg -i \{\} \;
# fi
