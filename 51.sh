#!/bin/bash
# Description: Installs and runs the FaceFusion WebUI.
# Functionalities:
#   - Copies a dummy script to `/usr/bin/openbox-session` and makes it executable. (Purpose unclear, possibly related to GUI environment expectations).
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD51_DIR).
#   - Creates the main directory for this UI (`$SD51_DIR`) and its output directory (`/config/outputs/51-facefusion`).
#   - Displays system information using `show_system_info`.
#   - Creates a dedicated Conda environment (`$SD51_DIR/env`) if it doesn't exist.
#   - Activates the Conda environment and installs Python 3.11, pip, git, gxx, and ffmpeg using libmamba solver.
#   - Copies default parameters from `/opt/sd-install/parameters/51.txt` to `$SD51_DIR/parameters.txt` if it doesn't exist.
#   - Clones or updates the FaceFusion repository (`facefusion/facefusion`) into `$SD51_DIR/facefusion` using `manage_git_repo`.
#   - Installs FaceFusion's main requirements from `$SD51_DIR/facefusion/requirements.txt`.
#   - Runs FaceFusion's specific installation script (`python3 install.py --onnxruntime cuda`) to set up ONNX Runtime with CUDA.
#   - Deactivates and reactivates the Conda environment (reason unclear, potentially to refresh paths after install.py).
#   - Installs additional Python requirements from `$SD51_DIR/requirements.txt` if it exists.
#   - Sets GRADIO_SERVER_NAME and GRADIO_SERVER_PORT environment variables for the Gradio interface.
#   - Constructs the launch command (`python3 facefusion.py run`) and appends parameters read from `$SD51_DIR/parameters.txt` within the same line.
#   - Executes the constructed command using `eval`. **Warning: Using eval is a security risk.**
#   - Uses `sleep infinity` to keep the script running after launching the UI.
# Choices and Reasons:
#   - Uses Conda (Python 3.11) for environment management. Installs `ffmpeg` and `gxx`, specific dependencies for FaceFusion.
#   - Leverages `manage_git_repo` for handling the FaceFusion source code repository.
#   - Includes a specific post-requirement installation step (`install.py`) required by FaceFusion.
#   - The conda deactivate/activate sequence is unusual and might warrant investigation.
#   - Reads launch parameters from a separate file (`parameters.txt`).
#   - Uses `eval` for command execution (unsafe).
#   - `sleep infinity` keeps the container alive.
# Usage Notes:
#   - Requires `functions.sh` and `/dummy.sh` (copied to openbox-session).
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables.
#   - `active_clean` (from entry.sh) would affect the Conda environment if implemented in `clean_env` for this path, but `clean_env` is not explicitly called here.
#   - Launch parameters are controlled via `$SD51_DIR/parameters.txt`.
#   - Additional Python dependencies can be added to `$SD51_DIR/requirements.txt`.
cp /dummy.sh /usr/bin/openbox-session
chmod +x /usr/bin/openbox-session
source /functions.sh

export PATH="/opt/miniconda3/bin:$PATH"
export SD51_DIR=${BASE_DIR}/51-facefusion

mkdir -p ${SD51_DIR}
mkdir -p /config/outputs/51-facefusion

show_system_info

if [ ! -d ${SD51_DIR}/env ]; then
    conda create -p ${SD51_DIR}/env -y
fi

source activate ${SD51_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.11 pip gxx ffmpeg --solver=libmamba -y


    if [ ! -f "$SD51_DIR/parameters.txt" ]; then
      cp -v "${SD_INSTALL_DIR}/parameters/51.txt" "$SD51_DIR/parameters.txt"
    fi

    # Install and update FaceFusion
    log_message "INFO" "Managing FaceFusion repository"
    if ! manage_git_repo "FaceFusion" \
        "https://github.com/facefusion/facefusion" \
        "${SD51_DIR}/facefusion"; then
        log_message "CRITICAL" "Failed to manage FaceFusion repository. Exiting."
        exit 1
    fi
 
 cd ${SD51_DIR}/facefusion 
 pip install -r requirements.txt
 python3 install.py --onnxruntime cuda
 
 conda deactivate
 source activate ${SD51_DIR}/env
 
 # install custom requirements
  pip install --upgrade pip

  if [ -f ${SD51_DIR}/requirements.txt ]; then
    pip install -r ${SD51_DIR}/requirements.txt
  fi

  
 export GRADIO_SERVER_NAME=0.0.0.0 
 export GRADIO_SERVER_PORT=9000 
 CMD="python3 facefusion.py run"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD51_DIR}/parameters.txt"; eval $CMD

sleep infinity
