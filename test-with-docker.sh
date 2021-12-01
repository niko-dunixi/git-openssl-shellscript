#!/usr/bin/env bash
cd "$(dirname "$0")"
# Utilize concurrency to build all the docker containers we'll use to test with
# - https://wiki.ubuntu.com/Releases
if [ "${#}" -eq 0 ]; then
  declare -a ubuntu_versions=("20.04" "18.04" "16.04" "14.04")
else
  declare -a ubuntu_versions=(${@})
fi

function build() {
  docker compose --project-directory docker-environment build ${ubuntu_versions[@]/#/ubuntu_}
}

function execute() {
  docker compose --project-directory docker-environment run --rm ${ubuntu_versions[@]/#/ubuntu_}
}

echo "Will test on the following ubuntu-distros: ${ubuntu_versions[@]}"
echo "Building testable ubuntu linux images... Fair warning, this will take a LONG time"
sleep 5s
time build
echo ""
echo "Executing script within the images. This will take a while"
sleep 5s
time execute
