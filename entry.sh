#!/bin/bash
# Description: This script is the entry point for the Docker container and is responsible for launching the Stable Diffusion WebUIs.
# Functionalities:
#   - Copies the custom-sample.sh script to the user's scripts directory if it doesn't already exist.
#   - Determines whether to clean the virtual environment based on the presence of the "Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch" file.
#   - Sources the appropriate .sh file based on the WEBUI_VERSION environment variable.
# Choices and Reasons:
#   - Copies the custom-sample.sh script to the user's scripts directory to provide a sample script for creating custom WebUIs.
#   - Determines whether to clean the virtual environment based on the presence of the "Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch" file to allow users to easily clean the environment.
#   - Sources the appropriate .sh file based on the WEBUI_VERSION environment variable to launch the correct WebUI.
#
# Additional Notes:
#   - This script requires the BASE_DIR and WEBUI_VERSION environment variables to be set.
#   - The script assumes that the .sh files for each WebUI are located in the root directory of the image.
#   - The script uses the source command to execute the .sh files, which means that any environment variables set in those files will be available to this script.

# Copy sample custom script in user folder if it doesn't exists

if [ ! -f "$BASE_DIR/scripts/custom-sample.sh" ]; then
    mkdir -p $BASE_DIR/scripts
    cp -v "/custom-sample.sh" "$BASE_DIR/scripts/custom-sample.sh"
fi

#  if file "Delete this file to clean virtual env and dependencies at next launch" isn't present
if [ -f "$BASE_DIR/Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch" ]; then
export active_clean=0
else
export active_clean=1
echo Delete this file to clean virtual env and dependencies at next launch > $BASE_DIR/Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch
fi

. /$WEBUI_VERSION.sh
. /$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION.sh 
echo error when launching WebUI
