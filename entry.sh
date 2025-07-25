#!/bin/bash

# Copy sample custom script in user folder if it doesn't exists

if [ ! -f "$BASE_DIR/scripts/custom-sample.sh" ]; then
    mkdir -p $BASE_DIR/scripts
    cp -v "/custom-sample.sh" "$BASE_DIR/scripts/custom-sample.sh"
fi

#  if file "Delete this file to clean virtual env and dependencies at next launch" isn't present
if [ -f "$BASE_DIR/Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch" ]; then
export active_clean=0
else
export active_clean=1
echo Delete this file to clean virtual env and dependencies at next launch > $BASE_DIR/Delete_this_file_to_clean_virtual_env_and_dependencies_at_next_launch
fi

      
# Handle KasmVNC session management to prevent restart loops.
# For UIs that do not require a graphical session, create a dummy openbox-session file.
# This prevents the s6 service from entering a restart loop.
case "$WEBUI_VERSION" in
    "72")
        # These UIs require a graphical session or have specific handling. Do nothing.
        echo "Graphical UI detected ($WEBUI_VERSION), letting KasmVNC manage the session."
        ;;
    *)
        # For all other UIs, create a dummy session file to satisfy the startup script.
        if [ ! -f "/usr/bin/openbox-session" ]; then
            echo "Non-graphical UI detected, creating dummy openbox-session."
            echo -e '#!/bin/bash\nexit 0' > /usr/bin/openbox-session
            chmod +x /usr/bin/openbox-session
        fi
        ;;
esac

. /$WEBUI_VERSION.sh
. /$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION
. $BASE_DIR/scripts/$WEBUI_VERSION.sh 
echo error when launching WebUI