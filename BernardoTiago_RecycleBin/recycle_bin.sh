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

main() {
    echo "Hello, Recycle Bin!"
}
main "$@"