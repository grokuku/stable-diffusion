#!/bin/bash
# Description: Installs and runs the IOPaint WebUI.
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD50_DIR).
#   - Creates the main directory for this UI (`$SD50_DIR/IOPaint`) and its output directory (`/config/outputs/50-IOPaint`).
#   - Creates a dedicated Conda environment (`$SD50_DIR/env`) if it doesn't exist.
#   - Activates the Conda environment and installs Python 3.11, pip, and git using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/50.txt` to `$SD50_DIR/parameters.txt` if it doesn't exist.
#   - Installs or upgrades IOPaint using pip. The version is determined by `$UI_BRANCH` (defaulting to 'latest').
#   - Installs additional Python requirements from `$SD50_DIR/requirements.txt` if it exists.
#   - Constructs the launch command (`iopaint start`) by appending parameters read from `$SD50_DIR/parameters.txt`.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.11) for environment management.
#   - Installs IOPaint directly via pip. Unlike other scripts, it doesn't use `manage_git_repo`, suggesting IOPaint is primarily distributed as a package.
#   - Model management/symlinking (`sl_folder`) is not performed, likely because IOPaint handles models differently or doesn't require the same shared structure.
#   - Reads launch parameters from a separate file (`parameters.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh`.
#   - Expects `BASE_DIR`, `SD_INSTALL_DIR`, and optionally `UI_BRANCH` environment variables.
#   - `active_clean` (from entry.sh) would affect the Conda environment if implemented in `clean_env` for this path, but `clean_env` is not explicitly called here.
#   - Launch parameters are controlled via `$SD50_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD50_DIR/requirements.txt`.
source /functions.sh

export PATH="/opt/miniconda3/bin:$PATH"
export SD50_DIR=${BASE_DIR}/50-IOPaint

mkdir -p "${SD50_DIR}/IOPaint"
mkdir -p /config/outputs/50-IOPaint

if [ ! -d ${SD50_DIR}/env ]; then
    conda create -p ${SD50_DIR}/env -y
fi

source activate ${SD50_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip --solver=libmamba -y

if [ ! -f "$SD50_DIR/parameters.txt" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/50.txt" "$SD50_DIR/parameters.txt"
fi

cd ${SD50_DIR}/IOPaint

pip3 install --upgrade "iopaint==${UI_BRANCH:-latest}"

# install custom requirements
pip install --upgrade pip

if [ -f ${SD50_DIR}/requirements.txt ]; then
    pip install -r ${SD50_DIR}/requirements.txt
fi

CMD="iopaint start"
while IFS= read -r param; do
    if [[ $param != \#* ]]; then
        CMD+=" ${param}"
    fi
done < "${SD50_DIR}/parameters.txt"

eval $CMD
sleep infinity
