#!/bin/bash

case $WEBUI_VERSION in
  01)
    . /01.sh
    ;;
  02)
    . /02.sh
    ;;
  03)
    . /03.sh
    ;;
  04)
    . /04.sh
    ;;
  05)
    . /05.sh
    ;;
  06)
    . /06.sh
    ;;
  07)
    . /07.sh
    ;;
  08)
    . /08.sh
    ;;
  20)
    . /20.sh
    ;;
  50)
    . /50.sh
    ;;
  51)
    . /51.sh
    ;;
  70)
    . /70.sh
    ;;
  *)
    echo error in webui selection variable
    ;;
esac
