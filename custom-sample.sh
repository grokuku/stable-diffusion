#!/bin/bash
# Description: This script installs and runs a custom WebUI based on Fooocus-MRE.
# Functionalities:
#   - Sets up the environment for the custom WebUI.
#   - Clones the Fooocus-MRE repository.
#   - Creates and activates a conda environment.
#   - Installs necessary Python packages.
#   - Creates symbolic links for models and outputs.
#   - Runs the custom WebUI.
# Choices and Reasons:
#   - Conda is used for environment management to isolate dependencies.
#   - Specific versions of Python and other packages are installed to ensure compatibility.
#   - Symbolic links are used to merge models to avoid duplication.
#   - The Fooocus-MRE is cloned from GitHub.
#
# Additional Notes:
#   - This script assumes that the /functions.sh file exists and contains necessary helper functions.
#   - The script uses environment variables such as BASE_DIR, which should be defined before running the script.
#   - The script clones the Fooocus-MRE from GitHub. Ensure that the repository is accessible and up-to-date.
#   - The script creates a conda environment with Python 3.10. This version should be compatible with Fooocus-MRE.
#   - The script creates symbolic links for models and outputs. This can save disk space but may cause issues if the source files are modified or deleted.
#   - The script installs cuda-cudart from the nvidia channel. This is necessary for running Fooocus-MRE with CUDA support.
#   - The script installs requirements from requirements_versions.txt. This file should contain specific versions of the required packages.
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"

# Set Variables and parameters

# Name of the custom WebUI (will be used for the program itself and the output directory)
export CustomNAME="FooocusMRE"

# Name of the base folder for custom WebUIs
export CustomBASE="00-custom"

# Complete Path for the program files
export CustomPATH="/config/$CustomBASE/$CustomNAME"

# Parameters to pass at launch
export CustomPARAMETERS="--listen 0.0.0.0 --port 9000"

# Folders creation (Program files and output)
mkdir -p ${CustomPATH}
mkdir -p $BASE_DIR/outputs/$CustomBASE/$CustomNAME

show_system_info

# Creation and Activation on the Conda Virtual Env
if [ ! -d ${CustomPATH}/env ]; then
    conda create -p ${CustomPATH}/env -y
fi
source activate ${CustomPATH}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge git python=3.10 pip --solver=libmamba -y
conda install -c nvidia cuda-cudart --solver=libmamba -y

# Clone/update program files
if [ ! -d ${CustomPATH}/Fooocus-MRE ]; then
    cd "${CustomPATH}" && git clone https://github.com/MoonRide303/Fooocus-MRE.git
fi
cd ${CustomPATH}/Fooocus-MRE
git pull -X ours

# Using the sl_folder to create symlinks needed to use the common models folder
sl_folder ${CustomPATH}/Fooocus-MRE/models checkpoints ${BASE_DIR}/models stable-diffusion
sl_folder ${CustomPATH}/Fooocus-MRE/models loras ${BASE_DIR}/models lora
sl_folder ${CustomPATH}/Fooocus-MRE/models vae ${BASE_DIR}/models vae
sl_folder ${CustomPATH}/Fooocus-MRE/models embeddings ${BASE_DIR}/models embeddings
sl_folder ${CustomPATH}/Fooocus-MRE/models hypernetworks ${BASE_DIR}/models hypernetwork
sl_folder ${CustomPATH}/Fooocus-MRE/models upscale_models ${BASE_DIR}/models upscale
sl_folder ${CustomPATH}/Fooocus-MRE/models clip_vision ${BASE_DIR}/models clip_vision
sl_folder ${CustomPATH}/Fooocus-MRE/models controlnet ${BASE_DIR}/models controlnet

sl_folder ${CustomPATH}/Fooocus-MRE outputs ${BASE_DIR}/outputs/$CustomBASE $CustomNAME

# installation of requirements
cd ${CustomPATH}/Fooocus-MRE
pip install -r requirements_versions.txt

# Launch Fooocus-MRE
python launch.py ${CustomPARAMETERS}
