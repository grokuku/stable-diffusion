#!/bin/bash

# Copy sample custom script in user folder if it doesn't exists

if [ ! -f "$BASE_DIR/scripts/custom-sample.sh" ]; then
    mkdir -p $BASE_DIR/scripts
    cp -v "/custom-sample.sh" "$BASE_DIR/scripts/custom-sample.sh"
fi

# reset rights if file "Delete this file to reset access rights" isn't present
if [ ! -f "config/Delete this file to reset access rights" ]; then
echo "chown'ing directory to ensure correct permissions."
chown -R abc:users /config
chmod -R 774 /config
chmod -R 664 /config/models
chmod -R 664 /config/outputs
find /config -type d -exec chmod 777 {} +
echo Delete this file to reset access rights > "/config/Delete this file to reset access rights"
echo "Done!"
fi


. /$WEBUI_VERSION.sh
. /$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION.sh 
echo error when launching WebUI