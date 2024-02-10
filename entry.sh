#!/bin/bash

# Copy sample custom script in user folder if it doesn't exists

if [ ! -f "$BASE_DIR/scripts/custom-sample.sh" ]; then
    mkdir -p $BASE_DIR/scripts
    cp -v "/custom-sample.sh" "$BASE_DIR/scripts/custom-sample.sh"
fi

. $BASE_DIR/$WEBUI_VERSION.sh
. $BASE_DIR/$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION.sh 
echo error in webui selection variable