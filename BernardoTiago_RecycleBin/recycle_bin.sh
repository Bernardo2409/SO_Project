#################################################
# Linux Recycle Bin Simulation
# Author: Bernardo Coelho n125059; Tiago Vale n125913 
# Date: 
# Description: Shell-based recycle bin system
#################################################

set -e
trap 'echo -e "${RED}Operation aborted."; exit 1' SIGINT SIGTERM 

# Global Configuration
RECYCLE_BIN_DIR="$HOME/BernardoTiago_RecycleBin"
FILES_DIR="$RECYCLE_BIN_DIR/files"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"
CONFIG_FILE="$RECYCLE_BIN_DIR/config"
LOG_FILE="$RECYCLE_BIN_DIR/recyclebin.log"



TEST_FILE="./TESTING.md"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

main() {
   
    # echo -e " Hello $(whoami)! \n"

    # Optional auto-init if not already created
    if [[ ! -d "$RECYCLE_BIN_DIR" ]]; then
        echo -e "\n ${YELLOW}Recycle Bin not found. Initializing automatically...\n ${NC}"
        initialize_recyclebin
    fi
    

    case "$1" in
        init)
            initialize_recyclebin
            ;;
        delete)
            check_quota
            quota_status=$?
            if [[ $quota_status -eq 0 ]]; then
                delete_file "${@:2}"
            fi
            ;;
        list)
            list_recycled "$2"
            ;;
        restore)
            restore_file "${@:2}"
            ;;
        search)
            search_recycled "${@:2}"
            ;;
        empty)
            empty_recyclebin "${@:2}"
            ;;
        help|-h|--help)
            display_help
            ;;
        show)
            show_statistics
            ;;
        clean)
            auto_cleanup
            ;;
        preview)
            preview_file "${@:2}"
            ;;
        *)
            echo -e "   Use: ${YELLOW}$0 help${NC}"
            echo "   It shows all available commands!" 
            exit 1
            ;;
    esac
}



 ##########
 # Return 0: success
 # Return 1: failure



#################################################
# Function: initialize_recyclebin
# Description: Creates recycle bin directory structure
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################

initialize_recyclebin() {
    # Check if recycle bin already exists
    if [[ -d "$RECYCLE_BIN_DIR" ]]; then
        echo -e "${YELLOW}Recycle bin already exists at:${NC} $RECYCLE_BIN_DIR"
        return 0
    fi

    # Create directory structure
    mkdir -p "$FILES_DIR" || {
        echo -e "${RED}Error:${NC} Failed to create recycle bin directories."
        return 1
    }

    # Create metadata file
    echo "# Recycle Bin Metadata" > "$METADATA_FILE"
    echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"

    # Create config file (default values)
    echo "MAX_SIZE_MB=1024" > "$CONFIG_FILE"
    echo "RETENTION_DAYS=30" >> "$CONFIG_FILE"

    # Create empty log file
    : > "$LOG_FILE"

    # Success message
    echo -e "${GREEN}Recycle bin successfully initialized at:${NC} $RECYCLE_BIN_DIR"
    return 0
    
}


################################################# 
# Function: delete_file 
# Description: Moves file/directory to recycle bin 
# Parameters: $1 - path to file/directory 
# Returns: 0 on success, 1 on failure 
#################################################

delete_file() {
    # Auto-initialize Recycle Bin if missing
    if [[ ! -d "$RECYCLE_BIN_DIR" ]]; then
        initialize_recyclebin
    fi

    if [[ ! -d "$FILES_DIR" ]]; then
        mkdir -p "$FILES_DIR" || {
            echo -e "${RED}Error:${NC} Failed to create files directory: $FILES_DIR" | tee -a "$LOG_FILE"
            return 1
        }
    fi

    # Safety checks
    if [[ ! -f "$METADATA_FILE" ]]; then
        echo -e "${YELLOW}Metadata file missing, reinitializing Recycle Bin...${NC}"
        initialize_recyclebin
    fi


    local success=0

    for item in "$@"; do
        # Validate existence
        if [[ ! -e "${item}" ]]; then
            echo "Error: '${item}' doesn't exist." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Prevent deletion of the recycle bin itself
        if [[ "${item}" == "${RECYCLE_BIN_DIR}"* ]]; then
            echo "Error: Cannot delete the Recycle Bin itself." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Security checks
        if [[ "${item}" == *".."* || -L "${item}" ]]; then
            echo "Error: Insecure or symbolic path '${item}'." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Check permissions
        if [[ ! -r "${item}" || ! -w "${item}" ]]; then
            echo "Error: Insufficient permissions for '${item}'." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Generate unique ID
        local id
        id="$(date +%s%N)_$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
        local dest_path="${FILES_DIR}/${id}"

        # Collect metadata
        local original_name original_path deletion_date file_size file_type permissions owner
        original_name="$(basename "${item}")"
        original_path="$(realpath "${item}")"
        deletion_date="$(date '+%Y-%m-%d %H:%M:%S')"
        file_size=$(stat -c%s "${item}" 2>/dev/null) # tamanho em bytes (sem vírgulas nem letras)
        file_type=$(file -b "${item}")
        permissions=$(stat -c %a "${item}" 2>/dev/null)
        owner=$(stat -c %U:%G "${item}" 2>/dev/null)

        # Move file/folder
        if mv "${item}" "${dest_path}" 2>>"$LOG_FILE"; then
            if echo "${id},${original_name},${original_path},${deletion_date},${file_size},${file_type},${permissions},${owner}" >> "${METADATA_FILE}"; then
                echo -e "${GREEN}Success:${NC} '${original_name}' moved to RecycleBin (ID: ${id})." | tee -a "${LOG_FILE}"
            else
                echo -e "${RED}Error:${NC} Failed to record metadata for '${original_name}'." | tee -a "${LOG_FILE}"
                success=1
            fi
        else
            echo -e "${RED}Error:${NC} Failed to move '${item}'." | tee -a "${LOG_FILE}"
            success=1
        fi

    done

    return $success
}



#################################################
# Function: list_recycled
# Description: Lists all items in recycle bin
# Parameters: None
# Returns: 0 on success
#################################################

list_recycled() {
    verif_rbin

    echo -e "${YELLOW}=== Files on Recycle Bin ===${NC}"

    # Valid lines??
    local total_items
    total_items=$(grep -vE '^\s*#|^\s*$' "${METADATA_FILE}" | tail -n +2 | wc -l)

    # If there are no files
    if [[ "$total_items" -eq 0 ]]; then
        echo -e "${YELLOW}Recycle Bin is empty.${NC}"
        return 0
    fi

    # Count how many files are
    echo -e "${GREEN}${total_items}${NC} file(s) found in Recycle Bin:"
    echo

    # Show details
    if [[ "$1" == "--detailed" ]]; then

        echo -e "$(printf '%0.s-' {1..224})"
        # Cabeçalho formatado corretamente
        printf "%-26s | %-23s | %-80s | %-20s | %-10s | %-12s | %-13s | %-10s\n" \
            "UniqueID" "Original filename" "Path" "Deletion date" "File size" "File type" "Permissions" "Owner"

        # Exibição dos dados
        grep -vE '^\s*#|^\s*$' "${METADATA_FILE}" | tail -n +2 | while IFS=',' read -r id name path date size type perms owner; do
            printf "%-26s | %-23s | %-80s | %-20s | %-10s | %-12s | %-13s | %-10s\n" \
                "${id}" "${name}" "${path}" "${date}" "${size}" "${type}" "${perms}" "${owner}"
        done


    else
        # Simple format
        echo -e "---------------------------------------------------------------------------------------------"
        printf "%-26s | %-23s | %-25s | %-10s\n" "UniqueID" "Original filename" "Deletion date" "File size"

        grep -vE '^\s*#|^\s*$' "${METADATA_FILE}" | tail -n +2 | while IFS=',' read -r id name path date size _; do
            printf "%-26s | %-23s | %-25s | %-10s\n" "${id}" "${name}" "${date}" "${size}"
        
        done
    echo -e "---------------------------------------------------------------------------------------------"
    

    fi
}




#################################################
# Function: restore_file
# Description: Restores a file from recycle bin to its original location
# Parameters: $1 - file ID or original name
# Returns: 0 on success, 1 on failure
#################################################

restore_file() {
    verif_rbin

    local query="$1"

    if [[ -z "$query" ]]; then
        echo -e "${RED}Error:${NC} Please specify the file ID or original name to restore."
        return 1
    fi

    # Search for the ID and Original name
    local entry
    entry=$(grep -F -- "${query}," "$METADATA_FILE" 2>/dev/null || grep -F -- ",${query}," "$METADATA_FILE" 2>/dev/null | head -n1)


    if [[ -z "$entry" ]]; then
        echo -e "${RED}Error:${NC} No file found with ID or name '${query}'."
        return 1
    fi

    IFS=',' read -r id original_name original_path deletion_date file_size file_type permissions owner <<< "$entry"
    local src_path="${FILES_DIR}/${id}"
    local dest_dir
    dest_dir="$(dirname "$original_path")"
    local dest_path="$original_path"

    # Verify if file exists in RecycleBin
    if [[ ! -e "$src_path" ]]; then
        echo -e "${RED}Error:${NC} The file '${original_name}' no longer exists in the recycle bin."
        
        sed -i "/^${id},/d" "$METADATA_FILE"
        return 1
    fi

    # Create directs if needed
    mkdir -p "$dest_dir" 2>/dev/null

    # If the file as the same name, rename automatically
    if [[ -e "$dest_path" ]]; then
        dest_path="${dest_path}_restored_$(date +%s)"
        echo -e "${YELLOW}Warning:${NC} File already exists. Restoring as '$(basename "$dest_path")'."
    fi

    # Restaure the file
    if mv "$src_path" "$dest_path" 2>>"$LOG_FILE"; then
        # Restaure all original permissions
        chmod "$permissions" "$dest_path" 2>/dev/null || true
        chown "$owner" "$dest_path" 2>/dev/null || true
        
        # Remove all metadata
        sed -i "/^${id},/d" "$METADATA_FILE"
        
        echo -e "${GREEN}Success:${NC} '${original_name}' restored to '${dest_path}'."
        return 0   
    else
        echo -e "${RED}Error:${NC} Failed to restore '${original_name}'."
        return 1   
    fi
}








#################################################
# Function: search_recycled
# Description: Display all the files that contains the pattern given by the user
# Parameters: $1 - search patterns
# Returns: 0 on success, 1 on failure
#################################################

search_recycled() {
    verif_rbin
    local pattern="$1"
    local caseInsensitive=0  # false at start

    if [[ "$2" == "-i" ]]; then
        caseInsensitive=1 # if -i then caseInsensitve = true
    fi

    if [[ -z "${pattern}" ]]; then
        echo -e "${YELLOW}Use:${NC} $0 search <term> [-i]"
        return 1
    fi

    echo -e "${GREEN}=== Search Results ===${NC}"
    printf "${CYAN}%-20s | %-15s | %-30s | %-12s | %-8s | %-10s | %-6s | %s${NC}\n" \
        "ID" "Name" "Path" "Date" "Size" "Type" "Perms" "Owner"

    if [[ "$caseInsensitive" -eq 1 ]]; then
        # caseIsensitive = true
        grep -iE "${pattern}" "${METADATA_FILE}" | grep -vE '^\s*#|^\s*$' | while IFS=',' read -r id name path date size type perms owner; do
            printf "%-20s | %-15s | %-30s | %-12s | %-8s | %-10s | %-6s | %s\n" \
                "${id}" "${name}" "${path}" "${date}" "${size}" "${type}" "${perms}" "${owner}"
        done
    else
        # no -i
        grep -F --no-ignore-case -- "${pattern}" "${METADATA_FILE}" | grep -vE '^\s*#|^\s*$' | while IFS=',' read -r id name path date size type perms owner; do
            printf "%-20s | %-15s | %-30s | %-12s | %-8s | %-10s | %-6s | %s\n" \
                "${id}" "${name}" "${path}" "${date}" "${size}" "${type}" "${perms}" "${owner}"
        done
    fi
}


#################################################
# Function: empty_recyclebin
# Description: Permanently deletes all items in recycle bin
# Parameters: $1 -> --foce (optional) $2 -> fileID (optional)
# Returns: 0 on success, 1 on failure
#################################################

empty_recyclebin() {
    verif_rbin

    local force=0
    local file="$1"

    if [[ "$1" == "--force" ]]; then
        force=1
        file="$2"
    fi

    # If no file is specified
    if [[ -z "${file}" ]]; then
        # --force
        if [[ "${force}" -eq 1 ]]; then
            echo -e "${RED} Deleting of files of ${FILES_DIR}${NC}"
            rm -rf "${FILES_DIR:?}"/*
            head -n 2 "${METADATA_FILE}" > "${METADATA_FILE}.tmp" && mv "${METADATA_FILE}.tmp" "${METADATA_FILE}"
            echo -e "${GREEN}RecycleBin successfully emptied.${NC}"
        # no --force
        else
            echo -e "${YELLOW}Are you sure you want to delete all files? (y/n) ${NC}"
            read res
            if [[ "${res}" =~ ^[Yy]$ ]]; then
                rm -rf "${FILES_DIR:?}"/*
                head -n 2 "${METADATA_FILE}" > "${METADATA_FILE}.tmp" && mv "${METADATA_FILE}.tmp" "${METADATA_FILE}"
                echo -e "${GREEN}Recycle Bin is empty..${NC}"
            else
                echo -e "${YELLOW}Operation canceled.${NC}"
            fi
        fi
    # File Specified
    else
        # --force
        if [[ "$force" -eq 1 ]]; then
            echo -e "${RED}Deleting ${file}${NC}"
            target=$(find "$FILES_DIR" -type f -name "${file}*" -print -quit)
            if [[ -n "$target" ]]; then
                rm -f "$target"
                awk -F',' -v id="$file" '$1 != id' "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
                echo -e "${GREEN}${file} successfully deleted.${NC}"
                return 0
            else
                echo -e "${RED}File ${file} not found in ${FILES_DIR}.${NC}"
                return 1
            fi
        # no --force
        else
            echo -e "${YELLOW}Are you sure you want to delete ${file}? (y/n) ${NC}"
            read res
            if [[ "$res" =~ ^[Yy]$ ]]; then
                echo -e "${RED}Deleting ${file}${NC}"
                target=$(find "$FILES_DIR" -type f -name "${file}*" -print -quit)
                if [[ -n "$target" ]]; then
                    rm -f "$target"
                    awk -F',' -v id="$file" '$1 != id' "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
                    echo -e "${GREEN}${file} successfully deleted.${NC}"
                    return 0
                else
                    echo -e "${RED}File ${file} not found in ${FILES_DIR}.${NC}"
                    return 1
                fi
            else
                echo -e "${YELLOW}Operation cancelled.${NC}"
                return 1
            fi
        fi
    fi

}

#################################################
# Function: verif_rbin
# Description: Auxiliary funtion to verify if the recycle bin was initialized
# Parameters: none
# Returns: 0
#################################################
verif_rbin() {
    if [[ ! -d "${RECYCLE_BIN_DIR}" ]]; then
        echo -e "${RED}Error:${NC} Unitialized RecycleBin! Uses: $0 init"
        exit 1
    fi
}



#################################################
# Function: display_help
# Description: Displays comprehensive usage information and examples
# Parameters: None
# Returns: 0
#################################################


display_help() {
    echo "  delete:    Move files to RecycleBin"
    echo "  list:      List deleted files (--detailed for details)"
    echo "  restore:   Restore the file by its original name or ID"
    echo "  search:    Search for deleted files"
    echo "  empty:     Empty the RecycleBin (--force to don't ask for comfirmation)"
    echo "  show:      Displays overall statistics of the recycle bin"
    echo "  clean:     Automatically deletes items older than the configured retention period"
    echo "  preview:   display first 10 lines of a file existent in the recycle bin"
    echo
}

#################################################
# Function: show_statistics
# Description: Displays overall statistics of the recycle bin
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################

show_statistics() {
    verif_rbin

    if [[ ! -f "$METADATA_FILE" ]]; then
        echo -e "${RED}Error:${NC} metadata file not found."
        return 1
    fi

    echo -e "\n${YELLOW}=== Recycle Bin Statistics ===${NC}\n"

    # Ignore commented lines and blanked lines
    total_items=$(grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | tail -n +2 | wc -l)

    if [[ "$total_items" -eq 0 ]]; then
        echo -e "${YELLOW}Recycle Bin is empty.${NC}"
        return 0
    fi

    # Total size in bytes
    total_size_bytes=$(grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | tail -n +2 | awk -F',' '
        {
            size=$5
            gsub(/[^0-9.]/,"",size)
            if ($5 ~ /K/) size *= 1024
            else if ($5 ~ /M/) size *= 1024*1024
            else if ($5 ~ /G/) size *= 1024*1024*1024
            total += size
        }
        END {print total}
    ')

    readable_total=$(numfmt --to=iec-i --suffix=B $total_size_bytes 2>/dev/null)

    # Calculate quoto (MAX_SIZE_MB)
    quota_mb=$(grep "MAX_SIZE_MB" "$CONFIG_FILE" | cut -d'=' -f2)
    quota_bytes=$((quota_mb * 1024 * 1024))
    quota_percent=$(awk -v used="$total_size_bytes" -v quota="$quota_bytes" 'BEGIN {printf "%.2f", (used/quota)*100}')

    # Counter by type
    file_count=$(grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | tail -n +2 | awk -F',' '$6 ~ /file/ {count++} END {print count+0}')
    dir_count=$(grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | tail -n +2 | awk -F',' '$6 ~ /directory/ {count++} END {print count+0}')

    # Oldest and Newest
    oldest_line=$(grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | tail -n +2 | sort -t',' -k4 | head -n 1)
    newest_line=$(grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | tail -n +2 | sort -t',' -k4 | tail -n 1)

    oldest_name=$(echo "$oldest_line" | awk -F',' '{print $2}')
    oldest_date=$(echo "$oldest_line" | awk -F',' '{print $4}')
    newest_name=$(echo "$newest_line" | awk -F',' '{print $2}')
    newest_date=$(echo "$newest_line" | awk -F',' '{print $4}')

    # Average Size
    avg_size=$(awk -v total="$total_size_bytes" -v n="$total_items" 'BEGIN {if (n>0) printf "%.0f", total/n; else print 0}')
    readable_avg=$(numfmt --to=iec-i --suffix=B $avg_size 2>/dev/null)

    # Formatted
    echo -e "${GREEN}Total items:           ${NC}${total_items}"
    echo -e "${GREEN}Total storage used:    ${NC}${readable_total} (${quota_percent}% of quota)"
    echo -e "${GREEN}Files:                 ${NC}${file_count}"
    echo -e "${GREEN}Directories:           ${NC}${dir_count}"
    echo -e "${GREEN}Oldest item:           ${NC}${oldest_name} (${oldest_date})"
    echo -e "${GREEN}Newest item:           ${NC}${newest_name} (${newest_date})"
    echo -e "${GREEN}Average file size:     ${NC}${readable_avg}\n"

    return 0
}

#################################################
# Function: auto_cleanup
# Description: Automatically deletes items older than the configured retention period
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################

auto_cleanup() {
    verif_rbin

    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error:${NC} Config file not found."
        return 1
    fi

    if [[ ! -f "$METADATA_FILE" ]]; then
        echo -e "${RED}Error:${NC} Metadata file not found."
        return 1
    fi

    # Read retention period from config (default 30 days if not defined)
    RETENTION_DAYS=$(grep "RETENTION_DAYS" "$CONFIG_FILE" | cut -d'=' -f2)
    if [[ -z "$RETENTION_DAYS" ]]; then
        RETENTION_DAYS=30
    fi

    echo -e "\n${YELLOW}=== Auto Cleanup Started ===${NC}"
    echo -e "Retention period: ${RETENTION_DAYS} days\n"

    local current_time cutoff_time
    current_time=$(date +%s)
    cutoff_time=$(date -d "-${RETENTION_DAYS} days" +%s)

    local deleted_count=0
    local total_size_deleted=0

    # Iterate over metadata entries (ignore header and comments)
    grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | tail -n +2 | while IFS=',' read -r id name path deletion_date size type perms owner; do
        # Convert deletion date to timestamp
        item_time=$(date -d "$deletion_date" +%s 2>/dev/null || echo 0)

        if (( item_time > 0 && item_time < cutoff_time )); then
            item_path="${FILES_DIR}/${id}"

            if [[ -e "$item_path" ]]; then
                # Try to remove the file
                rm -rf "$item_path" 2>>"$LOG_FILE" && {
                    deleted_count=$((deleted_count + 1))
                    # Convert human-readable size to bytes
                    numeric_size=$(echo "$size" | awk '
                        /[0-9]+K/ {sub(/K/,"",$1); print $1*1024; next}
                        /[0-9]+M/ {sub(/M/,"",$1); print $1*1024*1024; next}
                        /[0-9]+G/ {sub(/G/,"",$1); print $1*1024*1024*1024; next}
                        /^[0-9]+$/ {print $1*1; next}
                    ')
                    total_size_deleted=$((total_size_deleted + numeric_size))
                    echo -e "${GREEN}Deleted:${NC} '${name}' (older than ${RETENTION_DAYS} days)" | tee -a "$LOG_FILE"
                    # Remove metadata line
                    sed -i "/^${id},/d" "$METADATA_FILE"
                }
            fi
        fi
    done

    readable_size=$(numfmt --to=iec-i --suffix=B $total_size_deleted 2>/dev/null)

    echo -e "\n${GREEN}=== Auto Cleanup Summary ===${NC}"
    echo -e "Items deleted:        $deleted_count"
    echo -e "Total space cleared:  ${readable_size}\n"
}

#################################################
# Function: check_quota
# Description: Check if recycle bin exceeds MAX_SIZE_MB
# Parameters: 0
# Returns: 0 on success, 1 on max size exceeded
#################################################
check_quota() {

    # Size usage in bytes
    total_size=$(grep -vE '^\s*#|^\s*$' "$METADATA_FILE" | tail -n +2 | awk -F',' '
        {
            size=$5
            gsub(/[^0-9.]/,"",size)
            if ($5 ~ /K/) size *= 1024
            else if ($5 ~ /M/) size *= 1024*1024
            else if ($5 ~ /G/) size *= 1024*1024*1024
            total += size
        }
        END {print total}
    ')
    quota_mb=$(grep "^MAX_SIZE_MB=" $CONFIG_FILE | cut -d'=' -f2) # quota_mb = MAX_SIZE_MB
    
    #maxSize in bytes
    quota=$((quota_mb * 1024 * 1024))

    if [[ total_size -ge quota ]]; then
        echo -e "${RED} !WARNING!: Max size exceeded! ${NC}"
        echo -e "${YELLOW}Trigger auto-cleanup?${NC} (y/n)"
        read res
        if [[ "$res" =~ ^[Yy]$ ]]; then
            auto_cleanup
            return 0
        else
            return 1
        fi
    fi
    return 0
}

#################################################
# Function: preview_file
# Description: Show first 10 lines for text files in recycle bin
# Parameters: $1 fileID (not full path)
# Returns: 0 on success, 1 on failure
#################################################
preview_file() {
    local fileID="$1"
    local file_path="$FILES_DIR/$fileID"

    # Verify if fileID is null
    if [[ -z "$fileID" ]]; then
        echo -e "${YELLOW}Usage:${NC} preview_file <fileID>"
        return 1
    fi

    # Verify if file exists
    if [[ ! -f "$file_path" ]]; then
        echo -e "${RED}ERROR:${NC} File id '$fileID' does not exist."
        return 1
    fi

    # Verify if is a text file
    if file "$file_path" | grep -qi "text"; then
        echo "---------------------------------------------"
        head -n 10 "$file_path"
        echo "---------------------------------------------"
        return 0
    else
        echo -e "${YELLOW}Warning:${NC} '$fileID' Is in binary format."
        return 1
    fi
}

main "$@"