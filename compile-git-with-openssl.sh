#!/usr/bin/env bash
set -eu
# Gather command line options
SKIPTESTS=
BUILDDIR=
SKIPINSTALL=
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
set -x
BUILDDIR=${BUILDDIR:-$(mktemp -d)}
mkdir -p "${BUILDDIR}"
cd "${BUILDDIR}"

# Download the source tarball from GitHub
sudo apt-get update
sudo apt-get install curl jq -y
git_tarball_url="$(curl --retry 5 "https://api.github.com/repos/git/git/tags" | jq -r '.[0].tarball_url')"
curl -L --retry 5 "${git_tarball_url}" --output "git-source.tar.gz"
tar -xf "git-source.tar.gz" --strip 1

# Source dependencies
# Don't use gnutls, this is the problem package.
if sudo apt-get remove --purge libcurl4-gnutls-dev -y; then
  # Using apt-get for these commands, they're not supported with the apt alias on 14.04 (but they may be on later systems)
  sudo apt-get autoremove -y
  sudo apt-get autoclean
fi
# Meta-things for building on the end-user's machine
sudo apt-get install build-essential autoconf dh-autoreconf -y
# Things for the git itself
sudo apt-get install libcurl4-openssl-dev tcl-dev gettext asciidoc libexpat1-dev libz-dev -y

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
if [[ "${SKIPTESTS}" != "YES" ]]; then
  make test
fi

# Install
if [[ "${SKIPINSTALL}" != "YES" ]]; then
  # If you have an apt managed version of git, remove it
  if sudo apt-get remove --purge git -y; then
    sudo apt-get autoremove -y
    sudo apt-get autoclean
  fi
  # Install the version we just built
  sudo make install #install-doc install-html install-info
  echo "Make sure to refresh your shell!"
  bash -c 'echo "$(which git) ($(git --version))"'
fi
