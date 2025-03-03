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
#  if [ "$CLEAN_ENV" != "true" ] && [ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
  if [ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | \
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

# Fonction récursive pour installer les requirements.txt
#install_requirements() {
#    local directory="$1"
#    local requirements_file="$directory/requirements.txt"

#    if [ -f "$requirements_file" ]; then
#        echo "Installation des dépendances dans $directory ..."
#        pip install -r "$requirements_file"
#        echo "Dépendances installées avec succès dans $directory."
#    fi

#    # Parcours récursif des sous-dossiers
#    for subdir in "$directory"/*; do
#        if [ -d "$subdir" ]; then
#            install_requirements "$subdir"
#        fi
#    done
#}
install_requirements() {
    local directory="$1"
    local requirements_file="$directory/requirements.txt"

    if [ -f "$requirements_file" ]; then
        echo "Installation des dépendances dans $directory ..."
        pip install -r "$requirements_file"
        echo "Dépendances installées avec succès dans $directory."
    fi

    # Parcours des sous-dossiers du premier niveau uniquement
    for subdir in "$directory"/*; do
        if [ -d "$subdir" ]; then
            local subdir_requirements_file="$subdir/requirements.txt"
            if [ -f "$subdir_requirements_file" ]; then
                echo "Installation des dépendances dans $subdir ..."
                pip install -r "$subdir_requirements_file"
                echo "Dépendances installées avec succès dans $subdir."
            fi
        fi
    done
}

show_system_info() {
    log_message "INFO" "System information:"
    
    # Disk space
    local available_space=$(df -h . | awk 'NR==2 {print $4}')
    log_message "INFO" "Available disk space: ${available_space}"
    
    # RAM
    local available_ram=$(free -h | awk 'NR==2 {print $7}')
    log_message "INFO" "Available RAM: ${available_ram}"
    
    # GPU info if available
    if command -v nvidia-smi &> /dev/null; then
        local gpu_info=$(nvidia-smi --query-gpu=gpu_name,memory.free --format=csv,noheader)
        log_message "INFO" "GPU information: ${gpu_info}"
    fi
}

git_pull_with_check() {
    local repo_dir="$1"
    local branch="${2:-master}"
    
    log_message "INFO" "Checking repository status in $repo_dir"
    
    cd "$repo_dir" || {
        log_message "ERROR" "Cannot access directory $repo_dir"
        return 1
    }
    
    # Configure git to allow safe directory
    git config --global --add safe.directory "$repo_dir"
    
    # Fetch remote changes
    if ! git fetch origin "$branch"; then
        log_message "ERROR" "Failed to fetch from remote"
        return 1
    }
    
    # Get current and remote HEADs
    local_head=$(git rev-parse HEAD)
    remote_head=$(git rev-parse "origin/$branch")
    
    # Compare HEADs
    if [ "$local_head" != "$remote_head" ]; then
        log_message "INFO" "Updates available, pulling changes"
        if ! git pull -X ours; then
            log_message "ERROR" "Failed to pull updates"
            return 1
        fi
        log_message "INFO" "Successfully updated repository"
    else
        log_message "INFO" "Repository is up to date"
    fi
    
    return 0
}
