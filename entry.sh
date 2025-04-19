#!/bin/bash
# Description: Main entry point script for the Docker container. It sets up the environment and launches the selected Stable Diffusion WebUI.
# Functionalities:
#   - Ensures a sample custom script (`custom-sample.sh`) exists in the user's configuration directory (`$BASE_DIR/scripts`).
#   - Checks for a specific file (`Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch`) to determine if Conda environments should be cleaned (`active_clean` variable).
#   - Attempts to source (execute in the current shell) the script corresponding to the selected WebUI version (`$WEBUI_VERSION`).
# Choices and Reasons:
#   - Provides a sample script (`custom-sample.sh`) to guide users in adding their own UIs.
#   - Uses a marker file for triggering environment cleaning, offering a simple mechanism for users.
#   - Uses the `source` command (`.`) to run the selected UI script, allowing it to potentially modify the entry script's environment (e.g., activate a Conda environment).
# Usage Notes:
#   - Requires `BASE_DIR` and `WEBUI_VERSION` environment variables to be set before execution.
#   - `WEBUI_VERSION` should correspond to the prefix of the script to be launched (e.g., '01', '02', 'custom').
#   - The logic for sourcing the UI script attempts multiple paths and might not be robust if script locations or names change.

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

# Attempt to source the script corresponding to the selected WEBUI_VERSION.
# Note: This tries multiple locations and naming conventions.
# Using `source` means the script runs in the current shell environment.
# If the sourced script exits, this entry script might also terminate prematurely.
. /$WEBUI_VERSION.sh # Try sourcing from root with .sh extension
. /$WEBUI_VERSION # Try sourcing from root without extension
. $BASE_DIR/scripts/$WEBUI_VERSION # Try sourcing from user scripts directory without extension
. $BASE_DIR/scripts/$WEBUI_VERSION.sh # Try sourcing from user scripts directory with .sh extension

# Warning: This echo command will always execute after attempting to source the scripts above,
# regardless of whether the sourcing was successful or if the sourced script encountered an error.
# It does not reliably indicate an error in launching the WebUI itself.
echo error when launching WebUI
