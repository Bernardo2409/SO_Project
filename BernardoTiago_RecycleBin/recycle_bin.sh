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

TEST_FILE="SO_Project/BernardoTiago_RecycleBin/TESTING.md"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

main() {
    # TODO: Case $1 (para fazer ./recycle_bin.sh delete "file" | list --detailed...  ) 
    echo "Hello, Recycle Bin!"

    case "$1" in
        init)
            initialize_recyclebin
            ;;
        delete)
            delete_file "${@:2}"
            ;;
        list)
            list_recycled "$2"
            ;;
        *)
            echo "Uso: $0 {init|delete|list|...}" #Ir terminando...
            exit 1
            ;;
    esac
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
        echo -e "${GREEN}Recycle bin initialized at $RECYCLE_BIN_DIR${NC}"
        return 0
    else
        echo -e "${YELLOW}Recycle bin already exists${NC}"
        return 1
    fi
    return 0
}


################################################# 
# Function: delete_file 
# Description: Moves file/directory to recycle bin 
# Parameters: $1 - path to file/directory 
# Returns: 0 on success, 1 on failure 
#################################################

delete_file() {

    if [[ ! -d "$RECYCLE_BIN_DIR" ]]; then
        echo -e "${RED}RecycleBin não inicializada! Para inicializar $0 init${NC}"
        exit 1
    fi

    local success=0 # Flag variable: 0 if all deletions succeed, 1 if any fail

    for item in "$@"; do # Each argument represents a file or directory

        # Check if the item exists
        if [[ ! -e "$item" ]]; then
            echo "Error: '$item' does not exist." | tee -a "$LOG_FILE"
            success=1
            continue
        fi
        # Prevent deletion of the recycle bin itself
        if [[ "$item" == "$RECYCLE_BIN_DIR"* ]]; then
            echo "Error: You cannot delete the recycle bin itself." | tee -a "$LOG_FILE"
            success=1
            continue
        fi
        # Check if the user has read and write permissions
        if [[ ! -r "$item" || ! -w "$item" ]]; then
            echo "Error: Insufficient permissions to delete '$item'." | tee -a "$LOG_FILE"
            success=1
            continue
        fi

    
        # Generate unique ID for each deleted item
        ID="$(date +%s%N)_$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
        DEST_PATH="$FILES_DIR/$ID"  # ex: /home/bernardoc/.recycle_bin/files/24123123123123

        # Extract metadata
        ORIGINAL_NAME="$(basename "$item")" # Original filename or directory name 
        ORIGINAL_PATH="$(realpath "$item")" # Complete absolute path of original location 
        DELETION_DATE="$(date '+%Y-%m-%d %H:%M:%S')" # Timestamp when deleted (YYYY-MM-DD HH:MM:SS)
        FILE_SIZE=$(du -sh "$item" 2>/dev/null | cut -f1) # Size in bytes
        FILE_TYPE=$(file -b "$item") # Either "file" or "directory"
        PERMISSIONS=$(stat -c %a "$item" 2>/dev/null) # Original permission bits (e.g., 644, 755)
        OWNER=$(stat -c %U:%G "$item" 2>/dev/null) # Original owner and group (user:group format)


        echo ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER

        # Check disk space
        AVAIL_SPACE=$(df "$FILES_DIR" | awk 'NR==2 {print $4}')
        REQ_SPACE=$(du -k "$item" | awk '{print $1}')
        if (( REQ_SPACE > AVAIL_SPACE )); then
            echo "Error: Not enough disk space to move '$item'." | tee -a "$LOG_FILE"
            success=1
            continue
        fi

        # Move files to ~/.recycle_bin/files/ with unique ID as filename 
        mv "$item" "$DEST_PATH" 2>>"$LOG_FILE"
        if [[ $? -eq 0 ]]; then
            echo "$UNIQUE_ID,$ORIGINAL_NAME,$ABS_PATH,$TIMESTAMP,$SIZE,$TYPE,$PERMISSIONS,$OWNER" >> "$METADATA_FILE"
            echo "Success: '$ORIGINAL_NAME' moved to recycle bin (ID: $UNIQUE_ID)." | tee -a "$LOG_FILE"
        else
            echo "Error: Failed to move '$item' to recycle bin." | tee -a "$LOG_FILE"
            success=1
        fi
    done

    # Return final status
    if [[ $success -eq 0 ]]; then
        return 0  # All deletions succeeded
    else
        return 1  # At least one deletion failed
    fi
}


#################################################
# Function: list_recycled
# Description: Lists all items in recycle bin
# Parameters: None
# Returns: 0 on success
#################################################

list_recycled() {

    if [[ ! -d "$RECYCLE_BIN_DIR" ]]; then
        echo -e "${RED}RecycleBin não inicializada! Para inicializar $0 init${NC}"
        exit 1
    fi

    # Se o argumento for "--detailed"
    if [[ "$1" == "--detailed" ]]; then
        echo "=== Files in recyclebin (detailed) ==="

        # Ignora comentarios
        grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | while IFS=',' read -r ID NAME PATH DATE SIZE TYPE PERMS OWNER; do
            printf "%s | %s | %s | %s | %s | %s | %s | %s\n" \
                "$ID" "$NAME" "$PATH" "$DATE" "$SIZE" "$TYPE" "$PERMS" "$OWNER"
        done

    else
        echo "=== Files in recyclebin ==="

        grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | while IFS=',' read -r ID NAME PATH DATE SIZE TYPE PERMS OWNER; do
            printf "%s | %s | %s | %s\n" "$ID" "$NAME" "$DATE" "$SIZE"
        done
    fi

    return
}

main "$@"



#################################################
# Function: restore_file
# Description: Restores a file from recycle bin to its original location
# Parameters: $1 - file ID or original name
# Returns: 0 on success, 1 on failure
#################################################

restore_file() {
    local query="$1"

    if [[ -z "$query" ]]; then
        echo -e "${RED}Erro:${NC} É necessário indicar o ID ou nome do ficheiro a restaurar."
        return 1
    fi

    # Procura entrada correspondente
    entry=$(awk -F"," -v q="$query" '$1==q || $2==q {print; exit}' "$METADATA_FILE")

    if [[ -z "$entry" ]]; then
        echo -e "${RED}Erro:${NC} Nenhum ficheiro encontrado com ID/nome '$query'."
        return 1
    fi

    IFS=',' read -r ID ORIGINAL_NAME ORIGINAL_PATH DELETION_DATE FILE_SIZE FILE_TYPE PERMISSIONS OWNER <<< "$entry"

    SRC_PATH="$FILES_DIR/$ID"
    DEST_DIR="$(dirname "$ORIGINAL_PATH")"
    DEST_PATH="$ORIGINAL_PATH"

    # Verifica se ainda existe o ficheiro na reciclagem
    if [[ ! -e "$SRC_PATH" ]]; then
        echo -e "${RED}Erro:${NC} O ficheiro com ID '$ID' já não existe na reciclagem."
        return 1
    fi

    # Cria diretórios originais se necessário
    mkdir -p "$DEST_DIR" 2>/dev/null

    # Conflito: já existe ficheiro com o mesmo nome
    if [[ -e "$DEST_PATH" ]]; then
        echo -e "${YELLOW}Aviso:${NC} Já existe '$DEST_PATH'."
        echo "Escolhe uma opção: (O)verwrite / (R)ename / (C)ancel"
        read -r choice

        case "$choice" in
            [Oo]*) rm -rf "$DEST_PATH" ;;
            [Rr]*) DEST_PATH="${DEST_PATH}_$(date +%s)" ;;
            [Cc]*) echo "Restauração cancelada."; return 1 ;;
            *) echo "Opção inválida. Cancelado."; return 1 ;;
        esac
    fi

    # Restaura ficheiro
    if mv "$SRC_PATH" "$DEST_PATH" 2>>"$LOG_FILE"; then
        chmod "$PERMISSIONS" "$DEST_PATH" 2>/dev/null
        chown "$OWNER" "$DEST_PATH" 2>/dev/null
        sed -i "/^$ID,/d" "$METADATA_FILE"
        echo -e "${GREEN}Sucesso:${NC} '$ORIGINAL_NAME' restaurado para '$DEST_PATH'." | tee -a "$LOG_FILE"
        return 0
    else
        echo -e "${RED}Erro:${NC} Falha ao restaurar '$ORIGINAL_NAME'." | tee -a "$LOG_FILE"
        return 1
    fi
}