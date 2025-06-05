#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD72_DIR=${BASE_DIR}/72-OneTrainer

# Switch NGINX to proxy KasmVNC on port 9000 for the UI
sudo cp /opt/sd-install/parameters/nginx.txt /etc/nginx/sites-enabled/default
sudo nginx -s reload

mkdir -p ${SD72_DIR}
mkdir -p /config/outputs/72-OneTrainer

# Copy default launch parameters if they don't exist
if [ ! -f "$SD72_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/72.txt" "$SD72_DIR/parameters.txt"
fi

# Install or update the OneTrainer repository
if [ ! -d "${SD72_DIR}/OneTrainer/.git" ]; then
  echo "Cloning OneTrainer repository..."
  git clone https://github.com/Nerogar/OneTrainer.git "${SD72_DIR}/OneTrainer"
  cd "${SD72_DIR}/OneTrainer"
else
  echo "Existing OneTrainer repository found. Synchronizing..."
  cd "${SD72_DIR}/OneTrainer"
  check_remote "GIT_REF"
fi

# Clean the Conda environment if required
clean_env ${SD72_DIR}/OneTrainer/conda_env

# Create the Conda environment inside the OneTrainer folder
if [ ! -d ${SD72_DIR}/OneTrainer/conda_env ]; then
    conda create -p ${SD72_DIR}/OneTrainer/conda_env -y
fi

# Activate the environment and install base packages
source activate ${SD72_DIR}/OneTrainer/conda_env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.10 pip --solver=libmamba -y

# Install OneTrainer's Python requirements
pip install --upgrade pip
cd ${SD72_DIR}/OneTrainer/
pip install -r requirements.txt

# Install custom user requirements if specified
if [ -f ${SD72_DIR}/requirements.txt ]; then
    pip install -r ${SD72_DIR}/requirements.txt
fi

# Note: Model symlinking is not used for OneTrainer by default.
# sl_folder ${SD72_DIR}/OneTrainer/models ...

# Deactivate Conda before launching to let the start script handle it
conda deactivate
cd ${SD72_DIR}/OneTrainer/
echo "LAUNCHING OneTrainer !"
# Launch the UI in a new xterm window within the VNC session
xterm -hold -e "${SD72_DIR}/OneTrainer/start-ui.sh"
sleep infinity