#!/bin/bash

# Description: This script contains utility functions used by other scripts in the project.
# Functionalities:
#   - Logging messages with different levels (DEBUG, INFO, WARNING, ERROR, CRITICAL).
#   - Managing folders and symbolic links.
#   - Cleaning Conda environments.
#   - Checking Git repository status against remote.
#   - Installing Python requirements.
#   - Displaying system information.
#   - Cloning and updating Git repositories, including submodules.
# Choices and Reasons:
#   - Uses bash scripting for compatibility within the Docker environment.
#   - Provides colored console output for logs for better readability.
#   - Uses rsync for moving folders to preserve metadata.
#   - Uses Conda for environment management.
#   - Uses standard Git commands for repository management.
# Usage Notes:
#   - This script should be sourced by other scripts that need its functions.
#   - Ensure necessary tools like git, conda, rsync, date, df, free, nvidia-smi (optional) are available.
#   - The LOG_FILE variable defines the path for the log file.

# Log levels: DEBUG, INFO, WARNING, ERROR, CRITICAL
LOG_FILE="/config/sd-webui.log" # Path to the log file. Consider making this configurable.

# Function: log_message
# Description: Logs a message to both a file and the console with a timestamp and severity level.
# Parameters:
#   $1: level (string) - The severity level (DEBUG, INFO, WARNING, ERROR, CRITICAL).
#   $2: message (string) - The message to log.
# Functionality:
#   - Gets the current timestamp.
#   - Formats the log line including timestamp, level, and message.
#   - Appends the log line to the file specified by LOG_FILE.
#   - Prints the log line to the console with color-coding based on the level.
# Choices and Reasons:
#   - Provides both file logging (for persistence) and console logging (for immediate feedback).
#   - Uses ANSI escape codes for colored output to improve readability in the terminal.
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_line="[$timestamp] [$level] $message"
    
    # Always log to file
    echo "$log_line" >> "$LOG_FILE"
    
    # Display colored output to console based on level
    case "$level" in
        "DEBUG")   echo -e "\e[34m$log_line\e[0m" ;;  # Blue
        "INFO")    echo -e "\e[32m$log_line\e[0m" ;;  # Green
        "WARNING") echo -e "\e[33m$log_line\e[0m" ;;  # Yellow
        "ERROR")   echo -e "\e[31m$log_line\e[0m" ;;  # Red
        "CRITICAL") echo -e "\e[1;31m$log_line\e[0m" ;;  # Bold Red
    esac
}

# Function: sl_folder
# Description: Moves a source folder to a target location and replaces the original source folder with a symbolic link pointing to the new location.
#              This is typically used to centralize data (like models) while maintaining the expected directory structure for applications.
# Parameters:
#   $1: source_base_path (string) - The base path containing the source folder.
#   $2: source_folder_name (string) - The name of the folder to move.
#   $3: target_base_path (string) - The base path where the folder will be moved.
#   $4: target_folder_name (string) - The new name for the folder in the target location.
# Functionality:
#   - Creates the target directory if it doesn't exist.
#   - Uses rsync to copy the contents of the source folder to the target folder if the source exists.
#   - Removes the original source folder.
#   - Removes any pre-existing symbolic link at the source location to avoid errors.
#   - Creates a symbolic link at the original source location pointing to the new target folder.
#   - Handles a potential naming mismatch during symlink creation.
# Choices and Reasons:
#   - Uses `rsync -r` for robust recursive copying.
#   - Explicitly removes the old folder and any existing symlink before creating the new one to ensure a clean state.
#   - Provides informative echo messages during the process.
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

# Function: clean_env
# Description: Removes a specified directory if the 'active_clean' variable is set to "1".
#              Intended for cleaning up virtual environments (like Conda envs).
# Parameters:
#   $1: env_path (string) - The path to the environment directory to remove.
# Functionality:
#   - Checks if the global variable `active_clean` is equal to "1".
#   - If true, prints cleaning messages and removes the directory specified by $1 using `rm -rf`.
# Choices and Reasons:
#   - Relies on a global variable `active_clean` which must be set beforehand by the calling script. This allows conditional cleaning.
#   - Uses `rm -rf` for forceful recursive deletion. Use with caution.
clean_env()     {
if [ "$active_clean" = "1" ]; then
    echo "-------------------------------------"
    echo "Cleaning venv"
    rm -rf ${1}
    echo "Done!"
    echo -e "-------------------------------------\n"
fi
}

# Function: check_remote (Partially implemented/commented out logic)
# Description: Intended to check if a remote Git repository branch is ahead of the local branch.
#              If the remote is ahead or if CLEAN_ENV is true, it pulls the latest changes, potentially resetting local changes.
# Parameters: None (implicitly operates on the current directory's Git repo).
# Functionality (Based on active code):
#   - Compares the local HEAD commit hash with the remote branch's commit hash.
#   - If they differ OR if CLEAN_ENV is "true":
#     - Sets `active_clean=1` if CLEAN_ENV is "true".
#     - Performs `git reset --hard HEAD` (potentially dangerous, discards local changes).
#     - Performs `git pull -X ours` (pulls changes, favoring local changes in case of conflict).
#   - If local is up-to-date and CLEAN_ENV is not "true", it prints a message.
# Choices and Reasons:
#   - The logic seems complex and potentially problematic (e.g., `git reset --hard HEAD` followed by `git pull -X ours`).
#   - Relies on global variables `CLEAN_ENV` and `active_clean`.
#   - The commented-out `if` condition suggests previous attempts at different logic.
# Usage Notes:
#   - This function's current implementation might lead to unexpected behavior or data loss due to `git reset --hard`.
#   - It's recommended to review and potentially replace this with the logic in `git_pull_with_check` or `manage_git_repo`.
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

# Function: install_requirements (Commented out recursive version)
# Description: Recursively finds and installs requirements.txt files in a directory and all its subdirectories.
# Parameters:
#   $1: directory (string) - The starting directory to search for requirements.txt.
# Functionality:
#   - Checks for requirements.txt in the current directory and installs it.
#   - Recursively calls itself for each subdirectory.
# Usage Notes: This version is commented out in favor of the non-recursive version below.
#install_requirements() {
#    local directory="$1"
#    local requirements_file="$directory/requirements.txt"
#
#    if [ -f "$requirements_file" ]; then
#        echo "Installation des dépendances dans $directory ..."
#        pip install -r "$requirements_file"
#        echo "Dépendances installées avec succès dans $directory."
#    fi
#
#    # Parcours récursif des sous-dossiers
#    for subdir in "$directory"/*; do
#        if [ -d "$subdir" ]; then
#            install_requirements "$subdir"
#        fi
#    done
#}

# Function: install_requirements (Active non-recursive version)
# Description: Installs Python dependencies from requirements.txt files found in the specified directory and its immediate subdirectories (first level only).
# Parameters:
#   $1: directory (string) - The directory to search for requirements.txt files.
# Functionality:
#   - Installs dependencies from `requirements.txt` in the main directory ($1) if it exists.
#   - Iterates through the first level of subdirectories within $1.
#   - Installs dependencies from `requirements.txt` within each subdirectory if the file exists.
# Choices and Reasons:
#   - Limits the search to the first level of subdirectories, preventing potentially deep or unintended installations.
#   - Uses `pip install -r` which is the standard way to install requirements.
# Usage Notes:
#   - Assumes `pip` is available and configured for the correct Python environment.
install_requirements() {
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

# Function: show_system_info
# Description: Displays basic system information like available disk space, RAM, and GPU details (if available).
# Parameters: None.
# Functionality:
#   - Uses `df -h .` to get available disk space in the current directory's filesystem.
#   - Uses `free -h` to get available RAM.
#   - Uses `nvidia-smi` (if the command exists) to get GPU name and free memory.
#   - Logs the gathered information using the `log_message` function with INFO level.
# Choices and Reasons:
#   - Provides a quick overview of system resources relevant for resource-intensive tasks like Stable Diffusion.
#   - Uses standard Linux commands (`df`, `free`).
#   - Checks for `nvidia-smi` existence before attempting to use it, making GPU reporting optional.
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

# Function: git_pull_with_check
# Description: Checks a Git repository against its remote 'origin' branch and updates it by resetting if necessary.
# Parameters:
#   $1: repo_dir (string) - The path to the Git repository directory.
#   $2: branch (string, optional) - The branch to check against (defaults to 'master').
# Functionality:
#   - Changes into the repository directory.
#   - Configures the directory as a safe directory for Git operations.
#   - Fetches the latest changes from the remote origin for the specified branch.
#   - Compares the local HEAD commit hash with the remote branch's commit hash.
#   - If they differ, it performs a `git reset --hard origin/$branch` to force the local repository to match the remote, discarding local changes and commits.
#   - Logs information about the process and success/failure.
# Returns:
#   0 on success, 1 on failure (e.g., cannot access directory, fetch fails, reset fails).
# Choices and Reasons:
#   - Prioritizes keeping the local repository identical to the remote state, discarding any local modifications. This ensures a clean state based on the remote source.
#   - Uses `git reset --hard` for a forceful update. Be aware this deletes local changes.
#   - Includes error handling and logging for better diagnostics.
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
        log_message "INFO" "Updates available, resetting to remote state (discarding local changes)"
        if ! git reset --hard "origin/$branch"; then
            log_message "ERROR" "Failed to reset to remote state"
            return 1
        fi
        log_message "INFO" "Successfully updated repository"
    else
        log_message "INFO" "Repository is up to date"
    fi
    
    return 0
}

manage_git_repo() {
    local name="$1"
    local repo_url="$2"
    local target_dir="$3"
    local branch="${4:-${UI_BRANCH:-master}}"
    local submodules="$5"
# Function: manage_git_repo
# Description: Manages a Git repository: clones it if it doesn't exist, or updates it if it does. Also handles specified submodules.
# Parameters:
#   $1: name (string) - A descriptive name for the repository (used in log messages).
#   $2: repo_url (string) - The URL of the Git repository.
#   $3: target_dir (string) - The local directory where the repository should be cloned/managed.
#   $4: branch (string, optional) - The specific branch to clone or update (defaults to $UI_BRANCH or 'master').
#   $5: submodules (string, optional) - A colon-separated string of "submodule_url:submodule_branch" pairs.
# Functionality:
#   - Checks if the target directory exists.
#   - If not, clones the repository using `git clone -b $branch $repo_url $target_dir`.
#   - If it exists, calls `git_pull_with_check` to update the repository.
#   - If submodules are provided ($5):
#     - Parses the submodule string.
#     - For each submodule:
#       - Clones the submodule if it doesn't exist locally.
#       - If it exists, checks out the specified branch and pulls updates (`git pull -X ours`).
#   - Logs the process extensively using `log_message`.
# Returns:
#   0 on success, 1 on failure (clone or update fails).
# Choices and Reasons:
#   - Provides a unified way to handle both initial cloning and subsequent updates.
#   - Leverages the `git_pull_with_check` function for the update logic (which includes discarding local changes).
#   - Supports managing specific branches.
#   - Includes basic submodule handling (cloning, checking out branch, pulling). The `git pull -X ours` strategy favors local changes during submodule updates, which might differ from the main repo's update strategy.
#   - Uses `git config --global --add safe.directory` to handle potential Git security restrictions within Docker.
manage_git_repo() {
    local name="$1"
    local repo_url="$2"
    local target_dir="$3"
    local branch="${4:-${UI_BRANCH:-master}}"
    local submodules="$5"
# (Original comments below are now integrated into the main comment block above)
# Description: Manages a Git repository, cloning if it doesn't exist, otherwise pulling updates.
# Functionalities:
#   - Clones a Git repository from a given URL to a specified target directory.
#   - Updates an existing Git repository by fetching changes from the remote and resetting the local branch to match the remote.
#   - Handles submodules by cloning or updating them recursively.
# Choices and Reasons:
#   - Uses git clone to create a local copy of the repository if it doesn't exist.
#   - Uses git fetch and git reset --hard to update the local repository to match the remote, discarding any local changes.
#   - Recursively handles submodules to ensure that all dependencies are up-to-date.
#   - The function prioritizes keeping the local repository in sync with the remote, discarding local changes to avoid conflicts.
#   - The function uses git config --global --add safe.directory to configure git to allow safe directory
    log_message "INFO" "Starting repository management for $name"

    if [ ! -d "$target_dir" ]; then
        log_message "INFO" "Cloning $name from $repo_url (branch: $branch)"
        if ! git clone -b "$branch" "$repo_url" "$target_dir"; then
            log_message "CRITICAL" "Failed to clone $name repository"
            return 1
        fi
        log_message "INFO" "Successfully cloned $name"
    else
        if ! git_pull_with_check "$target_dir" "$branch"; then
            log_message "ERROR" "Failed to update $name repository"
            return 1
        fi
    fi

    # Handle submodules if specified
    if [ -n "$submodules" ]; then
        log_message "INFO" "Processing submodules for $name"
        while IFS=: read -r sub_url sub_branch; do
            local sub_name=$(basename "$sub_url" .git)
            local sub_dir="$target_dir/$sub_name"
            
            if [ ! -d "$sub_dir" ]; then
                if ! git clone -b "${sub_branch:-master}" "$sub_url" "$sub_dir"; then
                    log_message "ERROR" "Failed to clone submodule $sub_name"
                    continue
                fi
            else
                cd "$sub_dir" || {
                    log_message "WARNING" "Cannot access submodule directory $sub_dir"
                    continue
                }
                git config --global --add safe.directory "$sub_dir"
                if ! git checkout "${sub_branch:-master}"; then
                    log_message "WARNING" "Cannot switch to branch ${sub_branch:-master} for submodule $sub_name"
                    continue
                fi
                if ! git pull -X ours; then
                    log_message "WARNING" "Failed to update submodule $sub_name"
                fi
            fi
        done <<< "$submodules"
    fi

    return 0
}
