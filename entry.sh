#!/bin/bash

if [ ! -d /opt/miniconda3 ]; then
  su -w BASE_DIR - diffusion -c 'cd /home/diffusion && wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && rm Miniconda3-latest-Linux-x86_64.sh && export PATH="/opt/miniconda3/bin:$PATH"'
fi

chown -R diffusion:users /outputs
chown -R diffusion:users /home/diffusion
chown -R diffusion:users ${BASE_DIR}
chown -R diffusion:users /opt/miniconda3

case $WEBUI_VERSION in
  01)
    su -w XDG_CACHE_HOME -w SD01_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /01.sh'
    ;;
  02)
    su -w XDG_CACHE_HOME -w SD02_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /02.sh'
    ;;
  03)
    su -w XDG_CACHE_HOME -w SD03_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /03.sh'
    ;;
  04)
    su -w XDG_CACHE_HOME -w SD04_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /04.sh'
    ;;
  05)
    su -w XDG_CACHE_HOME -w SD05_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /05.sh'
    ;;
  06)
    su -w XDG_CACHE_HOME -w SD06_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /06.sh'
    ;;
  07)
    su -w XDG_CACHE_HOME -w SD07_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /07.sh'
    ;;
  08)
    su -w XDG_CACHE_HOME -w SD08_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /08.sh'
    ;;
  20)
    su -w XDG_CACHE_HOME -w SD20_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /20.sh'
    ;;
  50)
    su -w XDG_CACHE_HOME -w SD50_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /50.sh'
    ;;
  51)
    su -w XDG_CACHE_HOME -w SD51_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /51.sh'
        ;;
  70)
    su -w XDG_CACHE_HOME -w SD70_DIR -w BASE_DIR -w SD_INSTALL_DIR - diffusion -c '. /70.sh'
        ;;
  *)
    echo error in webui selection variable
    ;;
esac