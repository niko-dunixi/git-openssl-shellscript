#!/usr/bin/env bash
set -e

repository='paulnelsonbaker'
name='git-static-binary'
test_clone_url="https://github.com/paul-nelson-baker/git-openssl-shellscript.git"

set -x
docker build . -t "${name}:latest"

clone_directory="${HOME}/$(basename $(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'))"
mkdir -p "${clone_directory}"
docker run -v "${clone_directory}:/clone" -w '/clone' "${name}:latest" clone "${test_clone_url}"

git_version=$(docker run "${name}:latest" --version | awk '{ print $3 }')
docker tag "${name}:latest" "${repository}/${name}:${git_version}"
docker push "${repository}/${name}:${git_version}"

# Notes, still can't get curl to statically compile into git....
# Might need something like this? https://scripter.co/nim-deploying-static-binaries/