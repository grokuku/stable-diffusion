#!/bin/bash
source /functions.sh

export PATH="/home/abc/miniconda3/bin:$PATH"
export SD73_DIR=${BASE_DIR}/73-ai-toolkit

mkdir -p ${SD73_DIR}
mkdir -p /config/outputs/73-ai-toolkit

# Copy default launch parameters if they don't exist
if [ ! -f "$SD73_DIR/parameters.txt" ]; then
  cp -v "${SD_INSTALL_DIR}/parameters/73.txt" "$SD73_DIR/parameters.txt"
fi

# Install or update the ai-toolkit repository
if [ ! -d "${SD73_DIR}/ai-toolkit/.git" ]; then
  echo "Cloning ai-toolkit repository..."
  git clone https://github.com/ostris/ai-toolkit.git "${SD73_DIR}/ai-toolkit"
  cd "${SD73_DIR}/ai-toolkit"
else
  echo "Existing ai-toolkit repository found. Synchronizing..."
  cd "${SD73_DIR}/ai-toolkit"
  check_remote "GIT_REF"
fi

# Clean the Conda environment if required
clean_env ${SD73_DIR}/env

# Create the Conda environment if it doesn't exist
if [ ! -d ${SD73_DIR}/env ]; then
    conda create -p ${SD73_DIR}/env -y
fi

# Activate the environment and install base packages
source activate ${SD73_DIR}/env
conda install -n base conda-libmamba-solver -y
conda install -c conda-forge python=3.11 pip git nodejs --solver=libmamba -y

# Install Python requirements
pip install --upgrade pip
# As per instructions, install torch first with specific CUDA version
pip install --no-cache-dir torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0 --index-url https://download.pytorch.org/whl/cu126
# Install the project's requirements
cd ${SD73_DIR}/ai-toolkit/
pip install -r requirements.txt

# Install custom user requirements if specified
if [ -f ${SD73_DIR}/requirements.txt ]; then
    pip install -r ${SD73_DIR}/requirements.txt
fi

# Symlink shared models folders into the ai-toolkit directory
# Note: The target folder structure inside ai-toolkit is assumed to be a 'models' directory.
# This may need to be adjusted based on the actual structure of the tool.
#mkdir -p ${SD73_DIR}/ai-toolkit/models
#sl_folder ${SD73_DIR}/ai-toolkit/models stable-diffusion ${BASE_DIR}/models stable-diffusion
#sl_folder ${SD73_DIR}/ai-toolkit/models lora ${BASE_DIR}/models lora
#sl_folder ${SD73_DIR}/ai-toolkit/models vae ${BASE_DIR}/models vae
#sl_folder ${SD73_DIR}/ai-toolkit/models embeddings ${BASE_DIR}/models embeddings
#sl_folder ${SD73_DIR}/ai-toolkit/models hypernetwork ${BASE_DIR}/models hypernetwork
#sl_folder ${SD73_DIR}/ai-toolkit/models upscale ${BASE_DIR}/models upscale
#sl_folder ${SD73_DIR}/ai-toolkit/models controlnet ${BASE_DIR}/models controlnet

# Symlink the output folder
#sl_folder ${SD73_DIR}/ai-toolkit outputs ${BASE_DIR}/outputs 73-ai-toolkit

# Set the PORT environment variable for the npm script
export PORT=9000

# Launch the Node.js UI
echo "Building and launching AI-Toolkit UI..."
cd ${SD73_DIR}/ai-toolkit/ui
# The 'npm run build_and_start' command handles the UI.
# It's unlikely to use the parameters.txt file. Configuration is likely done within the UI's own files.
npm run build_and_start

sleep infinity