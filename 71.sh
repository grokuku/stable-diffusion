#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD71_DIR=${BASE_DIR}/71-fluxgym

log_message "INFO" "Starting Fluxgym installation and setup"

mkdir -p ${SD71_DIR}
show_system_info

# Install and update Fluxgym with SD-Scripts dependency
if ! manage_git_repo "Fluxgym" \
    "https://github.com/cocktailpeanut/fluxgym" \
    "${SD71_DIR}/fluxgym" \
    "${UI_BRANCH:-master}" \
    "https://github.com/kohya-ss/sd-scripts:sd3"; then
    log_message "CRITICAL" "Failed to manage Fluxgym repository. Exiting."
    exit 1
fi

# Clean conda env
log_message "INFO" "Cleaning conda environment"
clean_env ${SD71_DIR}/conda-env

# Create Conda virtual env
if [ ! -d ${SD71_DIR}/conda-env ]; then
    log_message "INFO" "Creating new conda environment"
    conda create -p ${SD71_DIR}/conda-env -y
fi

# Activate conda env + install base tools
log_message "INFO" "Installing conda packages"
source activate ${SD71_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip git --solver=libmamba -y

if [ ! -f "$SD71_DIR/parameters.txt" ]; then
    log_message "INFO" "Copying default parameters"
    cp -v "/opt/sd-install/parameters/71.txt" "$SD71_DIR/parameters.txt"
fi

# Create symbolic links
log_message "INFO" "Setting up model symbolic links"
sl_folder ${SD71_DIR}/fluxgym/models models ${BASE_DIR}/models fluxgym

sl_folder ${SD71_DIR}/fluxgym outputs ${BASE_DIR}/outputs 71-fluxgym

# Install requirements
log_message "INFO" "Installing Python requirements"
cd ${SD71_DIR}/fluxgym
pip install -r requirements.txt
if [ -f ${SD71_DIR}/requirements.txt ]; then
    log_message "INFO" "Installing additional requirements"
    pip install -r ${SD71_DIR}/requirements.txt
fi

# Run WebUI
log_message "INFO" "Launching Fluxgym WebUI"
cd ${SD71_DIR}/fluxgym
CMD="python app.py"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD71_DIR}/parameters.txt"
log_message "DEBUG" "Launch command: $CMD"
eval $CMD
sleep infinity