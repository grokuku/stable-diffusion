FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS builder
# Description: This Dockerfile defines the steps to build a Docker image for running Stable Diffusion WebUIs.
# Functionalities:
#   - Installs necessary dependencies for compiling Python packages, including Python 3.11, wget, gnupg, bc, rsync, libgl1-mesa-glx, libtcmalloc-minimal4, libcufft10, libxft2, xvfb, cmake, build-essential, ffmpeg, gcc-12, g++-12, ninja-build, and git.
#   - Configures gcc and g++ to use version 12.
#   - Clones and builds several Python packages from GitHub, including flash-attention, diso, nvdiffrast, kaolin, mip-splatting, and TRELLIS.
#   - Copies the built Python packages to a /build directory.
# Choices and Reasons:
#   - Uses a multi-stage build to reduce the size of the final image.
#   - Installs specific versions of Python and other packages to ensure compatibility.
#   - Clones and builds Python packages from GitHub to ensure that the latest versions are used.
#   - Configures gcc and g++ to use version 12 to ensure compatibility with the CUDA toolkit.
#
# Additional Notes:
#   - This Dockerfile requires Docker to be installed.
#   - The resulting image can be used to run Stable Diffusion WebUIs.
#   - The Dockerfile uses a base image from nvidia/cuda, which includes the CUDA toolkit.
#   - The Dockerfile installs several Python packages that are required for Stable Diffusion WebUIs.
#   - The Dockerfile configures gcc and g++ to use version 12, which is required for compiling some of the Python packages.

# Installer les dépendances nécessaires pour la compilation
RUN apt-get update

RUN apt-get install -y -q=2 software-properties-common && \
    apt-get install -y python3.11 python3.11-distutils python3.11-venv python3-pip python3.11-dev && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

    RUN apt-get install -y -q=2 wget \
    gnupg \
    bc \
    rsync \
    libgl1-mesa-glx \
    libtcmalloc-minimal4 \
    libcufft10 \
    libxft2 \
    xvfb \
    cmake \
    build-essential \
    ffmpeg \
    gcc-12 \
    g++-12 \
    ninja-build \
    git \
    gcc-12 g++-12

RUN pip install torch torchvision packaging

# Configurer gcc et g++
ENV CC=/usr/bin/gcc-12
ENV CXX=/usr/bin/g++-12
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.7 8.9 9.0 9.0a"
ENV CPLUS_INCLUDE_PATH=/usr/local/cuda/include:$CPLUS_INCLUDE_PATH
ENV LIBRARY_PATH=/usr/local/cuda/lib64:$LIBRARY_PATH
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH

# Créer un dossier pour les artefacts
WORKDIR /build

RUN git clone https://github.com/Dao-AILab/flash-attention --recurse-submodules
RUN cd flash-attention && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

RUN git clone https://github.com/SarahWeiii/diso --recurse-submodules && \
    cd diso && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

RUN git clone https://github.com/NVlabs/nvdiffrast.git && \
    cd nvdiffrast && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

RUN pip3 install torch==2.5.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124 && \
    git clone https://github.com/NVIDIAGameWorks/kaolin.git && \
    cd kaolin && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

RUN git clone https://github.com/autonomousvision/mip-splatting --recurse-submodules && \
    cd mip-splatting/submodules/diff-gaussian-rasterization && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

RUN git clone https://github.com/microsoft/TRELLIS --recurse-submodules && \
    cd TRELLIS/extensions/vox2seq && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

#ENV MAX_JOBS=1

#RUN git clone https://github.com/thu-ml/SageAttention --recurse-submodules && \
#    cd SageAttention && \
#    python3 setup.py bdist_wheel && \
#    cp dist/*.whl /build/

RUN cd 

FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy
# Description: This Dockerfile defines the steps to create the final Docker image for running Stable Diffusion WebUIs.
# Functionalities:
#   - Uses a base image from ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy, which provides a VNC server and other utilities.
#   - Copies the /docker/root directory to the root directory of the image.
#   - Sets several environment variables, including DEBIAN_FRONTEND, WEBUI_VERSION, CUSTOM_PORT, BASE_DIR, SD_INSTALL_DIR, XDG_CACHE_HOME, CC, CXX, TORCH_CUDA_ARCH_LIST, and UI_BRANCH.
#   - Installs several dependencies, including curl, software-properties-common, wget, gnupg, mc, bc, nano, rsync, libgl1-mesa-glx, libtcmalloc-minimal4, libcufft10, libxft2, xvfb, cmake, build-essential, ffmpeg, gcc-12, g++-12, dotnet-sdk-8.0, and git.
#   - Purges gcc-11, g++-11, and python3.
#   - Installs the CUDA toolkit.
#   - Copies the built Python packages from the builder image to the /wheels directory.
#   - Copies the .sh files to the root directory of the image and makes them executable.
#   - Sets the XDG_CONFIG_HOME and HOME environment variables.
#   - Installs miniconda.
#   - Exposes ports 9000 and 3000.
# Choices and Reasons:
#   - Uses a base image from ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy to provide a VNC server and other utilities.
#   - Copies the /docker/root directory to the root directory of the image to provide custom configurations and scripts.
#   - Sets several environment variables to configure the application.
#   - Installs several dependencies that are required for running Stable Diffusion WebUIs.
#   - Purges gcc-11, g++-11, and python3 to ensure that the correct versions are used.
#   - Installs the CUDA toolkit to enable GPU support.
#   - Copies the built Python packages from the builder image to the /wheels directory to avoid having to rebuild them.
#   - Copies the .sh files to the root directory of the image and makes them executable so that they can be run.
#   - Sets the XDG_CONFIG_HOME and HOME environment variables to ensure that the application can find its configuration files.
#   - Installs miniconda to provide a Python environment.
#   - Exposes ports 9000 and 3000 so that the WebUIs can be accessed from outside the container.
#
# Additional Notes:
#   - This Dockerfile requires Docker to be installed.
#   - The resulting image can be used to run Stable Diffusion WebUIs.
#   - The Dockerfile uses a base image from ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy, which provides a VNC server and other utilities.
#   - The Dockerfile installs several dependencies that are required for Stable Diffusion WebUIs.
#   - The Dockerfile configures gcc and g++ to use version 12, which is required for compiling some of the Python packages.
#   - The Dockerfile installs miniconda to provide a Python environment.

COPY docker/root/ /

ENV DEBIAN_FRONTEND=noninteractive
ENV WEBUI_VERSION=01
ENV CUSTOM_PORT=3000
ENV BASE_DIR=/config \
    SD_INSTALL_DIR=/opt/sd-install \
    XDG_CACHE_HOME=/config/temp
ENV CC=/usr/bin/gcc-12
ENV CXX=/usr/bin/g++-12
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.7 8.9 9.0 9.0a"

# Ajouter la variable d'environnement générique pour les branches des UI
ENV UI_BRANCH=master

RUN apt-get update -q && \
    apt-get install -y -q=2 curl \
    software-properties-common \
    wget \
    gnupg \
    mc \
    bc \
    nano \
    rsync \
    libgl1-mesa-glx \
    libtcmalloc-minimal4 \
    libcufft10 \
    libxft2 \
    xvfb \
    cmake \
    build-essential \
    ffmpeg \
    gcc-12 \
    g++-12 \
    dotnet-sdk-8.0 \
    git && \
    apt purge gcc-11 g++-11 -y && \
    apt-get purge python3 -y && \
# CUDA toolkit installation
    cd /tmp/ && \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    apt-get update && \
    apt-get -y install cuda-toolkit-12-4 && \
# CLEAN
    apt autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p ${BASE_DIR}\temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs

ADD parameters/* ${SD_INSTALL_DIR}/parameters/

RUN mkdir -p /root/defaults

COPY --from=builder /build/*.whl /wheels/

COPY --chown=abc:abc *.sh ./
RUN chmod +x /entry.sh

ENV XDG_CONFIG_HOME=/home/abc
ENV HOME=/home/abc
RUN mkdir /home/abc && \
    chown -R abc:abc /home/abc

RUN cd /tmp && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b && \
    rm Miniconda3-latest-Linux-x86_64.sh && \
    chown -R abc:abc /root && \
    chown -R abc:abc ${SD_INSTALL_DIR} && \
    chown -R abc:abc /home/abc

EXPOSE 9000/tcp
EXPOSE 3000/tcp
