#!/usr/bin/env bash

# Utilize concurrency to build all the docker containers we'll use to test with
echo "Building testable ubuntu linux images... Fair warning, this will take a LONG time"
sleep 5s
declare -a ubuntu_versions=("14.04" "16.04" "18.04" "18.10" "19.04")
function build_containers()
{
  for ubuntu_version in "${ubuntu_versions[@]}"; do
    dockerfile="ubuntu-${ubuntu_version//\.}"
    ubuntu_container="ubuntu:${ubuntu_version}-with-sudo"
    echo -e "${green}Building image ${ubuntu_container} from file ${dockerfile}${no_color}"
    docker build -t "${ubuntu_container}" -f "dockerfiles/${dockerfile}" ./dockerfiles &
  done
  # Wait for all jobs to complete
  for job_pid in $(jobs -p); do
    wait "${job_pid}"
  done
}
time build_containers


# Now working with the images individually so we can test the script on each container
echo "Running script in each container"
sleep 5s

temp_directory=$(mktemp -d)
results_file="${temp_directory}/test-results.txt"
green="\033[0;32m"
red="\033[0;31m"
no_color="\033[0m"
script_file="git-openssl.sh"
[ -f "${results_file} "] || rm "${results_file}"
for ubuntu_version in "${ubuntu_versions[@]}"; do
  ubuntu_container="ubuntu:${ubuntu_version}-with-sudo"
  echo "Testing with ${ubuntu_container}"
  docker run -v "$(pwd):/src" --rm --name "git-openssl-shellscript-test" "ubuntu:${ubuntu_version}-with-sudo" /bin/bash -c "/src/${script_file} --skip-tests"
  if [ "${?}" -ne 0 ]; then
    # echo "${red}Failed on ubuntu:${ubuntu_version}${no_color}" | tee -a "${results_file}"
    echo "Failed on ubuntu:${ubuntu_version}" >> "${results_file}"
  else
    # echo "${green}Worked on ubuntu:${ubuntu_version}${no_color}" | tee -a "${results_file}"
    echo "Worked on ubuntu:${ubuntu_version}" >> "${results_file}"
  fi
done
printf "\nFinal Results:\n"
cat "${results_file}"
echo -e "${no_color}"
