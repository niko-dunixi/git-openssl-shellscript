#!/usr/bin/env bash

declare -a ubuntu_versions=("14.04" "16.04" "18.04" "18.10" "19.04")
green="\033[0;32m"
red="\033[0;31m"
no_color="\033[0m"
script_file="git-openssl.sh"
results_file="test-results.txt"
[ -f "${results_file} "] || rm "${results_file}"
for ubuntu_version in "${ubuntu_versions[@]}"; do
  dockerfile="ubuntu-${ubuntu_version//\.}"
  ubuntu_container="ubuntu:${ubuntu_version}-with-sudo"
  echo -e "${green}Building image... from file ${dockerfile} to create ${ubuntu_container}${no_color}"
  docker build -t "${ubuntu_container}" -f "dockerfiles/${dockerfile}" ./dockerfiles
  docker run -v "$(pwd):/src" --rm --name "git-openssl-shellscript-test" "ubuntu:${ubuntu_version}-with-sudo" /bin/bash -c "/src/${script_file}"
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
#  docker run -v /path/to/sample_script.sh:/sample_script.sh \
#   --rm ubuntu bash sample_script.sh
