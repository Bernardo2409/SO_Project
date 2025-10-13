#################################################
# Linux Recycle Bin Simulation
# Author: Bernardo Coelho n125059; Tiago Vale n125913 
# Date: 
# Description: Shell-based recycle bin system
#################################################

# Global Configuration
RECYCLE_BIN_DIR="$HOME/BernardoTiago_RecycleBin"
FILES_DIR="$RECYCLE_BIN_DIR/files"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"
CONFIG_FILE="$RECYCLE_BIN_DIR/config"
LOG_FILE="$RECYCLE_BIN_DIR/recyclebin.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

main() {
    echo "Hello, Recycle Bin!"

    initialize_recyclebin
}


#################################################
# Function: initialize_recyclebin
# Description: Creates recycle bin directory structure
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################
initialize_recyclebin() {
    if [[ ! -d "$RECYCLE_BIN_DIR" ]]; then
        mkdir -p "$FILES_DIR"

        touch "$CONFIG_FILE" "$LOG_FILE" "$METADATA_FILE"

        #RecycleBin Metadata
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"

        #Config File
        echo "MAX_SIZE_MB=1024" > "$CONFIG_FILE"

        #Empty LogFile
        echo "Recycle bin initialized at $RECYCLE_BIN_DIR"
        return 0
    else
        echo "Recycle bin already exists"
        return 1
    fi
    return 0
}

main "$@"