FROM ghcr.io/grokuku/stable-diffusion-buildbase:latest

# Copy s6-overlay and custom service configuration
COPY docker/root/ /

# --- Environment Variables ---
ENV DEBIAN_FRONTEND=noninteractive
ENV WEBUI_VERSION=01
ENV CUSTOM_PORT=3000
ENV BASE_DIR=/config \
    SD_INSTALL_DIR=/opt/sd-install \
    XDG_CACHE_HOME=/config/temp

# Set compiler and Torch/CUDA architecture for any potential runtime compilations
ENV CC=/usr/bin/gcc-13
ENV CXX=/usr/bin/g++-13
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.7 8.9 9.0 9.0a 10"

# --- System & Package Installation ---
RUN apt-get update -q && \
    # Install system dependencies for Ubuntu 24.04, removing conflicting/obsolete packages
    apt-get install -y -q=2 curl \
    software-properties-common \
    wget \
    gnupg \
    mc \
    bc \
    nano \
    rsync \
    libxft2 \
    xvfb \
    cmake \
    build-essential \
    ffmpeg \
    gcc-13 \
    g++-13 \
    dotnet-sdk-8.0 \
    git && \
    # Remove any conflicting system Python to ensure Conda's version is used
    apt-get purge python3 -y && \
    # Install CUDA Toolkit for Ubuntu 24.04
    cd /tmp/ && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get -y install cuda-toolkit-12-8 && \
    # Clean up package cache
    apt autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# --- Application Setup ---
# Create application directories
RUN mkdir -p ${BASE_DIR}\temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs

# Copy WebUI parameters
ADD parameters/* ${SD_INSTALL_DIR}/parameters/

RUN mkdir -p /root/defaults

# Copy and set permissions for all launch scripts
COPY --chown=abc:abc *.sh ./
RUN chmod +x /entry.sh

# --- User and Environment Setup ---
# Set home directory for the application user
ENV XDG_CONFIG_HOME=/home/abc
ENV HOME=/home/abc
RUN mkdir /home/abc && \
    chown -R abc:abc /home/abc

# Install Miniforge for Python environment management (uses conda-forge by default)
RUN cd /tmp && \
    # URL for Miniforge installer
    wget https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh && \
    # Install Miniforge directly into the path expected by all launch scripts
    bash Miniforge3-Linux-x86_64.sh -b -p /home/abc/miniconda3 && \
    rm Miniforge3-Linux-x86_64.sh && \
    # Set final ownership for application folders
    chown -R abc:abc /root && \
    chown -R abc:abc ${SD_INSTALL_DIR} && \
    chown -R abc:abc /home/abc

# Expose default ports
EXPOSE 9000/tcp
EXPOSE 3000/tcp