#!/bin/bash

#Function to move folder and replace with symlink
sl_folder()     {
  echo "moving folder ${1}/${2} to ${3}/${4}"
  mkdir -p "${3}/${4}"
  if [ -d "${1}/${2}" ]; then
    rsync -r "${1}/${2}/" "${3}/${4}/" --verbose
  fi
  echo "removing folder ${1}/${2} and create symlink"
  if [ -d "${1}/${2}" ]; then
    rm -rf "${1}/${2}"
  fi
  
  # always remove previous symlink
  # b/c if user changed target locations current symlink will be incorrect
  if [ -L "${1}/${2}" ]; then
    rm "${1}/${2}"
  fi
  # create symlink
  ln -s "${3}/${4}/" "${1}"
  if [ ! -L "${1}/${2}" ]; then
    mv "${1}/${4}" "${1}/${2}"
  fi
}

clean_env()     {
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Cleaning venv"
    rm -rf ${1}
    echo "Done!"
    echo -e "-------------------------------------\n"
fi
}

# check if remote is ahead of local
# https://stackoverflow.com/a/25109122/1469797
check_remote()     {
  if [ "$CLEAN_ENV" != "true" ] && [ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
sed 's/\// /g') | cut -f1) ]; then
    echo "Local branch up-to-date, keeping existing venv"
    else
        if [ "$CLEAN_ENV" = "true" ]; then
        echo "Forced wiping venv for clean packages install"
        export active_clean=1
        else
        echo "Remote branch is ahead. If you encouter any issue after upgrade, try to clean venv for clean packages install"
        fi
    
    git reset --hard HEAD
    git pull -X ours
fi
}