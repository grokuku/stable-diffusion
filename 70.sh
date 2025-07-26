#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD70_DIR=${BASE_DIR}/70-kohya

mkdir -p ${SD70_DIR}
mkdir -p /config/outputs/70-kohya

# Copy default launch parameters if they don't exist
if [ ! -f "$SD70_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/70.txt" "$SD70_DIR/parameters.txt"
fi

# Install or update the Kohya_ss repository
if [ ! -d "${SD70_DIR}/kohya_ss/.git" ]; then
  echo "Cloning Kohya_ss repository..."
  cd "${SD70_DIR}" && git clone https://github.com/bmaltais/kohya_ss "${SD70_DIR}/kohya_ss"
  cd "${SD70_DIR}/kohya_ss"
else
  echo "Existing Kohya_ss repository found. Synchronizing..."
  cd "${SD70_DIR}/kohya_ss"
  check_remote "KOHYA_GIT_REF"
fi

# Clean the Conda environment if required
clean_env ${SD70_DIR}/env

# Create the Conda environment if it doesn't exist
if [ ! -d ${SD70_DIR}/env ]; then
    conda create -p ${SD70_DIR}/env -y
fi

# Activate the environment and install base packages
source activate ${SD70_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip --solver=libmamba -y

# Install Kohya's Python requirements using its setup script
pip install --upgrade pip
cd ${SD70_DIR}/kohya_ss
python ./setup/setup_linux.py
cd ${SD70_DIR}/kohya_ss

# Install custom user requirements if specified
if [ -f ${SD70_DIR}/requirements.txt ]; then
    pip install -r ${SD07_DIR}/requirements.txt
fi

# Launch Kohya_ss GUI
echo "LAUNCHING KOHYA_SS !"
CMD="python kohya_gui.py"; while IFS= read -r param; do if [[ $param != \#* ]]; then CMD+=" ${param}"; fi; done < "${SD70_DIR}/parameters.txt"; eval $CMD

sleep infinity