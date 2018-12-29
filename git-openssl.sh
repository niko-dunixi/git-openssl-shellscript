#!/usr/bin/env bash
set -e

# Gather command line options
for i in "$@"; do 
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

# Build it!
make configure
# --prefix=/usr
#    Set the prefix based on this decision tree: https://i.stack.imgur.com/BlpRb.png
#    Not OS related, is software, not from package manager, has dependencies, and built from source => /usr
# --with-openssl
#    Running ripgrep on configure shows that --with-openssl is set by default. Since this could change in the
#    future we do it explicitly
./configure --prefix=/usr --with-openssl
make 
make all #doc info
if [[ "${SKIPTESTS}" != "YES" ]]; then
  make test
fi

# Install
if [[ "${SKIPINSTALL}" != "YES" ]]; then
  # If you have an apt managed version of git, remove it
  if apt remove --purge git; then
    sudo apt-get autoremove -y
    sudo apt-get autoclean
  fi
  # Install the version we just built
  make install #install-doc install-html install-info
  echo "Make sure to refresh your shell!"
  bash -l -c 'echo "$(which git) ($(git --version))"'
fi
