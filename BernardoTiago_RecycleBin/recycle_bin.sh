#################################################
# Linux Recycle Bin Simulation
# Author: Bernardo Coelho n125059; Tiago Vale n125913 
# Date: 
# Description: Shell-based recycle bin system
#################################################

set -e
trap 'echo -e "${RED}Operação interrompida. Saída segura.${NC}"; exit 1' SIGINT SIGTERM

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
    # TODO: Case $1 (./recycle_bin.sh delete "file" | list --detailed...  ) 
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
        search)
            search_recycled "$2"
            ;;
        restore)
            restore_file "${@:2}"
            ;;
        empty)
            empty_recyclebin "${@:2}"
            ;;
        *)
            echo "Uso: $0 {init|delete|list|search|restore|empty...}" 
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
        mkdir -p "$FILES_DIR" || { echo "Erro ao criar diretórios."; return 1; }
        touch "$CONFIG_FILE" "$LOG_FILE" "$METADATA_FILE" || { echo "Erro ao criar ficheiros."; return 1; }


        # Metadata
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
    
}


################################################# 
# Function: delete_file 
# Description: Moves file/directory to recycle bin 
# Parameters: $1 - path to file/directory 
# Returns: 0 on success, 1 on failure 
#################################################

delete_file() {
    # Verifica se o recycle bin foi inicializado
    if [[ ! -d "$RECYCLE_BIN_DIR" ]]; then
        echo -e "${RED}RecycleBin não inicializada! Para inicializar: $0 init${NC}"
        return 1
    fi
    local success=0

    for item in "$@"; do
        # Validate existence
        if [[ ! -e "${item}" ]]; then
            echo "Erro: '${item}' não existe." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Prevent deletion of the recycle bin itself
        if [[ "${item}" == "${RECYCLE_BIN_DIR}"* ]]; then
            echo "Erro: Não é permitido eliminar a reciclagem." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Security checks
        if [[ "${item}" == *".."* ]]; then
            echo "Erro: Caminho inseguro '${item}'." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi
        if [[ -L "${item}" ]]; then
            echo "Erro: Links simbólicos não são permitidos." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Check permissions
        if [[ ! -r "${item}" || ! -w "${item}" ]]; then
            echo "Erro: Permissões insuficientes para eliminar '${item}'." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Generate unique ID for each deleted item
        local id
        id="$(date +%s%N)_$(tr -dc 'a-z0-9' </dev/urandom | head -c 6)"
        local dest_path="${FILES_DIR}/${id}"

        # Extract metadata
        local original_name original_path deletion_date file_size file_type permissions owner
        original_name="$(basename "${item}")"
        original_path="$(realpath "${item}")"
        deletion_date="$(date '+%Y-%m-%d %H:%M:%S')"
        file_size=$(du -sh "${item}" 2>/dev/null | cut -f1)
        file_type=$(file -b "${item}")
        permissions=$(stat -c %a "${item}" 2>/dev/null)
        owner=$(stat -c %U:%G "${item}" 2>/dev/null)

        # Disk space check
        local avail_space req_space
        avail_space=$(df "${FILES_DIR}" | awk 'NR==2 {print $4}')
        req_space=$(du -k "${item}" | awk '{print $1}')
        if (( req_space > avail_space )); then
            echo "Erro: Espaço em disco insuficiente para mover '${item}'." | tee -a "${LOG_FILE}"
            success=1
            continue
        fi

        # Move file/folder
        if mv "${item}" "${dest_path}"; then
            echo "${id},${original_name},${original_path},${deletion_date},${file_size},${file_type},${permissions},${owner}" >> "${METADATA_FILE}"
            echo -e "${GREEN}Sucesso:${NC} '${original_name}' movido para reciclagem (ID: ${id})." | tee -a "${LOG_FILE}"
        else
            echo -e "${RED}Erro:${NC} Falha ao mover '${item}' para reciclagem." | tee -a "${LOG_FILE}"
            success=1
        fi
    done

    # Retorna status final
    if [[ $success -eq 0 ]]; then
        return 0  # Todas as eliminações foram bem-sucedidas
    else
        return 1  # Pelo menos uma eliminação falhou
    fi
}


#################################################
# Function: list_recycled
# Description: Lists all items in recycle bin
# Parameters: None
# Returns: 0 on success
#################################################

list_recycled() {

    verif_rbin

    echo "=== Ficheiros na reciclagem ==="

    if [[ "$1" == "--detailed" ]]; then
        grep -vE '^\s*#|^\s*$' "${METADATA_FILE}" | while IFS=',' read -r id name path date size type perms owner; do
            printf "%s | %s | %s | %s | %s | %s | %s | %s\n" \
                "${id}" "${name}" "${path}" "${date}" "${size}" "${type}" "${perms}" "${owner}"
        done
    else
        grep -vE '^\s*#|^\s*$' "${METADATA_FILE}" | while IFS=',' read -r id name path date size _; do
            printf "%s | %s | %s | %s\n" "${id}" "${name}" "${date}" "${size}"
        done
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

    if [[ -z "${query}" ]]; then
        echo -e "${RED}Erro:${NC} Indica o ID ou nome do ficheiro a restaurar."
        return 1
    fi

    local entry
    entry=$(awk -F"," -v q="${query}" '{gsub(/\r/,""); if ($1==q || $2==q) {print; exit}}' "${METADATA_FILE}")

    if [[ -z "${entry}" ]]; then
        echo -e "${RED}Erro:${NC} Nenhum ficheiro encontrado com ID/nome '${query}'."
        return 1
    fi

    IFS=',' read -r id original_name original_path deletion_date file_size file_type permissions owner <<< "${entry}"
    src_path="${FILES_DIR}/${id}"
    dest_dir="$(dirname "${original_path}")"
    dest_path="${original_path}"

    if [[ ! -e "${src_path}" ]]; then
        echo -e "${RED}Erro:${NC} O ficheiro com ID '${id}' já não existe na reciclagem."
        return 1
    fi

    mkdir -p "${dest_dir}" 2>/dev/null

    if [[ -e "${dest_path}" ]]; then
        echo -e "${YELLOW}Aviso:${NC} Já existe '${dest_path}'."
        echo "Escolhe uma opção: (O)verwrite / (R)ename / (C)ancel"
        read -r choice
        case "${choice}" in
            [Oo]*) rm -rf "${dest_path}" ;;
            [Rr]*) dest_path="${dest_path}_$(date +%s)" ;;
            [Cc]*) echo "Restauração cancelada."; return 1 ;;
            *) echo "Opção inválida. Cancelado."; return 1 ;;
        esac
    fi

    if mv "${src_path}" "${dest_path}" 2>>"${LOG_FILE}"; then
        chmod "${permissions}" "${dest_path}" 2>/dev/null
        chown "${owner}" "${dest_path}" 2>/dev/null
        sed -i "/^${id},/d" "${METADATA_FILE}"
        echo -e "${GREEN}Sucesso:${NC} '${original_name}' restaurado para '${dest_path}'." | tee -a "${LOG_FILE}"
    else
        echo -e "${RED}Erro:${NC} Falha ao restaurar '${original_name}'." | tee -a "${LOG_FILE}"
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

    if [[ -z "${pattern}" ]]; then
        echo -e "${YELLOW}Uso:${NC} $0 search <termo>"
        return 1
    fi

    echo "=== Resultados ==="
    grep -iE "${pattern}" "${METADATA_FILE}" | grep -vE '^\s*#|^\s*$' | while IFS=',' read -r id name path date size type perms owner; do
        printf "%s | %s | %s | %s | %s | %s | %s | %s\n" \
            "${id}" "${name}" "${path}" "${date}" "${size}" "${type}" "${perms}" "${owner}"
    done
}

#################################################
# Function: empty_recyclebin
# Description: Permanently deletes all items in recycle bin
# Parameters: $1 - search patterns
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

    if [[ -z "${file}" ]]; then
        if [[ "${force}" -eq 1 ]]; then
            echo -e "${RED}A apagar todos os arquivos de ${FILES_DIR}${NC}"
            rm -rf "${FILES_DIR:?}"/*
            head -n 2 "${METADATA_FILE}" > "${METADATA_FILE}.tmp" && mv "${METADATA_FILE}.tmp" "${METADATA_FILE}"
            echo -e "${GREEN}Reciclagem esvaziada com sucesso.${NC}"
        else
            read -e -p "${YELLOW}Tens a certeza que queres apagar todos os ficheiros? (y/n) ${NC}" res
            if [[ "${res}" =~ ^[Yy]$ ]]; then
                rm -rf "${FILES_DIR:?}"/*
                head -n 2 "${METADATA_FILE}" > "${METADATA_FILE}.tmp" && mv "${METADATA_FILE}.tmp" "${METADATA_FILE}"
                echo -e "${GREEN}Reciclagem esvaziada.${NC}"
            else
                echo -e "${YELLOW}Operação cancelada.${NC}"
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
        echo -e "${RED}Erro:${NC} Reciclagem não inicializada! Usa: $0 init"
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
    echo "Uso: $0 {init|delete|list|search|restore|empty}"
    echo
    echo " HELP: Comandos disponíveis:"
    echo "  init:      Inicializa a reciclagem"
    echo "  delete:    Move ficheiro(s) para a reciclagem"
    echo "  list:      Lista os ficheiros eliminados (--detailed para detalhes)"
    echo "  search:    Pesquisa os ficheiros eliminados"
    echo "  restore:   Restaura os ficheiro pelo ID ou nome original"
    echo "  empty:     Esvazia a reciclagem (--force para não pedir confirmação)"
    echo
}



main "$@"