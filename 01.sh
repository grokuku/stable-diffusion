#!/bin/bash
# Description: Installs and runs the Easy Diffusion WebUI (v3.0.2).
# Functionalities:
#   - Sources shared utility functions from /functions.sh.
#   - Sets up necessary environment variables (PATH, SD01_DIR).
#   - Conditionally cleans the Conda environment and installer files based on the `active_clean` variable (set in entry.sh).
#   - Creates a dedicated Conda environment (`conda-env`) if it doesn't exist.
#   - Activates the Conda environment and installs Python 3.11 and pip using libmamba solver.
#   - Creates necessary subdirectories within SD01_DIR (models, version, plugins/ui, scripts).
#   - Downloads a specific plugin manager JavaScript file directly from GitHub.
#   - Uses the `sl_folder` function (from functions.sh) to create symbolic links from the shared model directories (`$BASE_DIR/models`) to the expected locations within `$SD01_DIR/models`. This avoids duplicating model files.
#   - Creates a symbolic link for the output directory.
#   - Copies a default configuration file (`parameters/01.txt`) to `$SD01_DIR/config.yaml` if it doesn't exist.
#   - Downloads and extracts the Easy Diffusion v3.0.2 release zip file if `start.sh` is not present.
#   - Executes the `start.sh` script provided by Easy Diffusion to launch the UI.
#   - Uses `sleep infinity` to keep the script (and potentially the container) running after launching the UI.
# Choices and Reasons:
#   - Uses Conda for robust environment isolation, specifying Python 3.11 for compatibility. Libmamba solver is used for potentially faster dependency resolution.
#   - Downloads a specific version (v3.0.2) of Easy Diffusion for reproducibility. Using a fixed version avoids unexpected changes from upstream updates.
#   - Employs symbolic links (`sl_folder`) for model directories to efficiently share models across different UIs managed by this project structure, saving disk space.
#   - Downloads the plugin manager directly via curl; this might be fragile if the URL changes.
#   - The `sleep infinity` command is a simple way to keep the container alive after starting the main process, but a proper process manager within the container (like supervisord or s6-overlay, which seems partially set up in docker/root) might be more robust for handling the application lifecycle.
# Usage Notes:
#   - Requires `functions.sh` to be available.
#   - Expects `BASE_DIR` and `SD_INSTALL_DIR` environment variables to be set.
#   - The `active_clean` variable (set by `entry.sh`) controls whether the environment is wiped before setup.
#   - Installs Easy Diffusion v3.0.2. To update, the download URL and potentially other steps might need changes.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD01_DIR=${BASE_DIR}/01-easy-diffusion

#clean conda env
clean_env ${SD01_DIR}/conda-env
clean_env ${SD01_DIR}/installer_files

#Create Conda Env
if [ ! -d ${SD01_DIR}/conda-env ]; then
    conda create -p ${SD01_DIR}/conda-env -y
fi

#active env and install python
source activate ${SD01_DIR}/conda-env
conda install -n base conda-libmamba-solver -y
conda install -c python=3.11 pip --solver=libmamba -y

#create 'models' folders
mkdir -p ${SD01_DIR}/{models,version,plugins/ui,scripts}
cd ${SD01_DIR}

#install manager plugin
if [ ! -f ${SD01_DIR}/plugins/ui/plugin-manager.plugin.js ]; then
    curl -L https://raw.githubusercontent.com/patriceac/Easy-Diffusion-Plugins/main/plugin-manager.plugin.js --output ${SD01_DIR}/plugins/ui/plugin-manager.plugin.js
fi

# Merge Models, vae, lora, hypernetworks, etc.
sl_folder ${SD01_DIR}/models stable-diffusion ${BASE_DIR}/models stable-diffusion
sl_folder ${SD01_DIR}/models hypernetwork ${BASE_DIR}/models hypernetwork
sl_folder ${SD01_DIR}/models lora ${BASE_DIR}/models lora
sl_folder ${SD01_DIR}/models vae ${BASE_DIR}/models vae
sl_folder ${SD01_DIR}/models controlnet ${BASE_DIR}/models controlnet
sl_folder ${SD01_DIR}/models realesrgan ${BASE_DIR}/models upscale
sl_folder ${SD01_DIR}/models codeformer ${BASE_DIR}/models codeformer
sl_folder ${SD01_DIR}/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${SD01_DIR}/models gfpgan ${BASE_DIR}/models gfpgan

sl_folder ${HOME} "Stable Diffusion UI" ${BASE_DIR}/outputs 01-Easy-Diffusion

#copy default parameters if they don't exists
if [ ! -f "$SD01_DIR/config.yaml" ]; then
    cp -v "${SD_INSTALL_DIR}/parameters/01.txt" "$SD01_DIR/config.yaml"
fi

#download installer if it isn't present
if [ ! -f "$SD01_DIR/start.sh" ]; then
    curl -L https://github.com/easydiffusion/easydiffusion/releases/download/v3.0.2/Easy-Diffusion-Linux.zip --output edui.zip
    unzip edui.zip
    cp -rf easy-diffusion/* .
    rm -rf easy-diffusion
    rm -f edui.zip
fi

#run easy-diffusion
cd $SD01_DIR
bash start.sh
sleep infinity
