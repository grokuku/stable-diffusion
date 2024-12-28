#FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS builder
FROM ubuntu:22.04 AS builder

# Installer les dépendances nécessaires pour la compilation
RUN apt-get update && \
    apt-get install -y -q=2 curl \
    software-properties-common \
    wget \
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
    python3 \
    python3-pip \
    python3-venv \
    ninja-build \
    git \
    gcc-12 g++-12
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
    dpkg -i cuda-keyring_1.1-1_all.deb && \
    rm cuda-keyring_1.1-1_all.deb  # Supprimer le fichier .deb après installation
RUN apt-get update && \
    apt-get install -y cuda-toolkit-12-4 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

    RUN pip install torch torchvision packaging

# Configurer gcc et g++
ENV CC=/usr/bin/gcc-12
ENV CXX=/usr/bin/g++-12
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.7 8.9 9.0 9.0a"
#ENV PATH="/usr/local/cuda/bin:${PATH}"
#ENV LD_LIBRARY_PATH="/usr/local/cuda/lib64:${LD_LIBRARY_PATH}"

# Créer un dossier pour les artefacts
WORKDIR /build

# Compiler et installer diff-gaussian-rasterizatio et simple-knn
RUN git clone https://github.com/Dao-AILab/flash-attention --recurse-submodules && \
    cd flash-attention && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

RUN git clone https://github.com/SarahWeiii/diso --recurse-submodules && \
    cd diso && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

    # Compiler et installer nvdiffrast
RUN git clone https://github.com/NVlabs/nvdiffrast.git && \
    cd nvdiffrast && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/

# Compiler et installer kaolin
RUN git clone https://github.com/NVIDIAGameWorks/kaolin.git && \
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

RUN git clone https://github.com/JeffreyXiang/diffoctreerast --recurse-submodules && \
    cd diffoctreerast && \
    python3 setup.py bdist_wheel && \
    cp dist/*.whl /build/
    
FROM ghcr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

COPY docker/root/ /

ENV DEBIAN_FRONTEND=noninteractive
ENV WEBUI_VERSION=01
ENV CUSTOM_PORT=3000
ENV BASE_DIR=/config \
    SD_INSTALL_DIR=/opt/sd-install \
    XDG_CACHE_HOME=/config/temp
# Configurer gcc et g++
ENV CC=/usr/bin/gcc-12
ENV CXX=/usr/bin/g++-12
ENV TORCH_CUDA_ARCH_LIST="8.0 8.6 8.7 8.9 9.0 9.0a"

RUN apt-get update -q && \
#    apt-get install -y software-properties-common && \
#    add-apt-repository -y ppa:mozillateam/ppa && \
#    echo 'Package: firefox* \nPin: release o=LP-PPA-mozillateam \nPin-Priority: 1001' > /etc/apt/preferences.d/mozillateamppa && \
#    apt-get update -y -q=2 && \
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
#    dotnet-sdk-8.0 \
    gcc-12 \
    g++-12 \
    git && \
    apt purge gcc-11 g++-11 -y && \
    apt-get purge python3 -y && \
    apt autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Télécharger et installer le package cuda-keyring
#RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb && \
#    dpkg -i cuda-keyring_1.1-1_all.deb && \
#    rm cuda-keyring_1.1-1_all.deb  # Supprimer le fichier .deb après installation

# Mettre à jour les dépôts et installer le CUDA Toolkit
#RUN apt-get update && \
#    apt-get install -y cuda-toolkit-12-6 && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
RUN chmod +x ./dotnet-install.sh
RUN ./dotnet-install.sh  --channel 8.0

RUN mkdir -p ${BASE_DIR}\temp ${SD_INSTALL_DIR} ${BASE_DIR}/outputs

ADD parameters/* ${SD_INSTALL_DIR}/parameters/

RUN mkdir -p /root/defaults
#RUN echo "firefox" > root/defaults/autostart

COPY --from=builder /build/*.whl /wheels/
#COPY /wheels/*.whl /wheels/

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
