# Using a specific version for the base image
FROM ubuntu:jammy

# Creating a new user and group
RUN adduser --system --ingroup users --disabled-login --gecos "diffusion user" --shell /bin/bash --uid 99 diffusion

# Setting environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV WEBUI_VERSION=01
ENV BASE_DIR="/opt/stable-diffusion"
ENV SD_INSTALL_DIR="/opt/sd-install"
ENV SD01_DIR="${BASE_DIR}/01-easy-diffusion"
ENV SD02_DIR="${BASE_DIR}/02-sd-webui"
ENV SD03_DIR="${BASE_DIR}/03-invokeai"
ENV SD04_DIR="${BASE_DIR}/04-SD-Next"
ENV SD05_DIR="${BASE_DIR}/05-comfy-ui"
ENV SD06_DIR="${BASE_DIR}/06-Fooocus"
ENV SD07_DIR="${BASE_DIR}/07-StableSwarm"
ENV SD08_DIR="${BASE_DIR}/08-voltaML"
ENV SD20_DIR="${BASE_DIR}/20-kubin"
ENV SD50_DIR="${BASE_DIR}/50-lama-cleaner"
ENV SD51_DIR="${BASE_DIR}/51-facefusion"
ENV SD70_DIR="${BASE_DIR}/70-kohya"
ENV XDG_CACHE_HOME="${BASE_DIR}/temp"

# Installing required packages
RUN apt-get update -y -q=2 && \
    apt-get install -y -q=2 curl wget mc nano rsync libgl1-mesa-glx libtcmalloc-minimal4 libcufft10 cmake build-essential python3-opencv libopencv-dev dotnet-sdk-7.0
#    apt-get install -y -q=2 curl unzip bzip2 gpg mc nano rsync wget python3 python3-tk python3-venv git python3-pip build-essential ffmpeg \
#        libglew-dev libglfw3-dev libglm-dev libgl1-mesa-glx python3-opencv libopencv-dev \
#        libao-dev libmpg123-dev google-perftools
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
	
# Creating necessary directories
RUN mkdir -p \
    ${XDG_CACHE_HOME} \
    ${SD_INSTALL_DIR} \
    /outputs
	
# Adding necessary files
ADD parameters/* ${SD_INSTALL_DIR}/parameters/
ADD *.sh /

# Making the entry script executable and changing ownership of directories
RUN chmod +x /*.sh
RUN chown -R 99:100 /opt
RUN chown -R 99:100 /outputs
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && rm Miniconda3-latest-Linux-x86_64.sh

# Specifying volumes
VOLUME ${BASE_DIR}
VOLUME /outputs
VOLUME /home/diffusion/.cache

# Exposing necessary port
EXPOSE 9000

# Running the entry script
CMD ["/entry.sh"]
