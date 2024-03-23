#!/bin/bash

# Copy sample custom script in user folder if it doesn't exists

if [ ! -f "$BASE_DIR/scripts/custom-sample.sh" ]; then
    mkdir -p $BASE_DIR/scripts
    cp -v "/custom-sample.sh" "$BASE_DIR/scripts/custom-sample.sh"
fi

#  if file "Delete this file to clean virtual env and dependencies at next launch" isn't present
if [ -f "$BASE_DIR/Delete this file to clean virtual env and dependencies at next launch" ]; then
export active_clean=0
else
export active_clean=1
echo Delete this file to clean virtual env and dependencies at next launch > $BASE_DIR/'Delete this file to clean virtual env and dependencies at next launch'
fi

. /$WEBUI_VERSION.sh
. /$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION.sh 
echo error when launching WebUI