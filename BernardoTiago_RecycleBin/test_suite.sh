#!/bin/bash 
 
# Test Suite for Recycle Bin System 
 
SCRIPT="./recycle_bin.sh" 
TEST_DIR="test_data" 
PASS=0 
FAIL=0 
 
# Colors 
GREEN='\033[0;32m' 
RED='\033[0;31m' 
NC='\033[0m' 
 
# Test Helper Functions 
setup() { 
    mkdir -p "$TEST_DIR" 
    rm -rf ~/.recycle_bin 

    # Run initialization to create a fresh structure
    bash "$SCRIPT" init > /dev/null 2>&1

    # Clean metadata file (keep only headers)
    if [[ -f "$HOME/BernardoTiago_RecycleBin/metadata.db" ]]; then
        head -n 2 "$HOME/BernardoTiago_RecycleBin/metadata.db" > "$HOME/BernardoTiago_RecycleBin/metadata.tmp"
        mv "$HOME/BernardoTiago_RecycleBin/metadata.tmp" "$HOME/BernardoTiago_RecycleBin/metadata.db"
    fi
} 
 
teardown() { 
    rm -rf "$TEST_DIR" 
    rm -rf ~/.recycle_bin 
} 
 
assert_success() { 
    if [ $? -eq 0 ]; then 
        echo -e "${GREEN}✓ PASS${NC}: $1" 
        ((PASS++)) 
    else 
        echo -e "${RED}✗ FAIL${NC}: $1" 
        ((FAIL++)) 
    fi 
} 
 
assert_fail() { 
    if [ $? -ne 0 ]; then 
        echo -e "${GREEN}✓ PASS${NC}: $1" 
        ((PASS++)) 
    else 
        echo -e "${RED}✗ FAIL${NC}: $1" 
        ((FAIL++)) 
    fi 
} 
 
 
 
# Test Cases 

reset_metadata() {
    echo -e "${YELLOW}Resetting Recycle Bin metadata...${NC}"
    head -n 2 "${METADATA_FILE}" > "${METADATA_FILE}.tmp" && mv "${METADATA_FILE}.tmp" "${METADATA_FILE}"
    echo -e "${GREEN}Recycle Bin metadata cleared.${NC}"
}


# Initialize recycle bin structure
test_initialization() { 
    echo "=== Test: Initialization ===" 
    setup 
    $SCRIPT help > /dev/null 
    assert_success "Initialize recycle bin" 
    [ -d ~/.recycle_bin ] && echo "✓ Directory created" 
    [ -f ~/.recycle_bin/metadata.db ] && echo "✓ Metadata file created" 
} 
 
# Delete single file
test_delete_file() { 
    echo -e "\n=== Test: Delete File ===" 
    setup 
    echo "test content" > "$TEST_DIR/test.txt" 
    $SCRIPT delete "$TEST_DIR/test.txt" 
    assert_success "Delete existing file" 
    [ ! -f "$TEST_DIR/test.txt" ] && echo "✓ File removed from original 
location" 
} 

# Delete multiple files in one command
test_delete_multiple_files() {
    echo -e "\n=== Test: Delete Multiple Files ==="
    setup

    # Cria ficheiros de teste
    echo "file1" > "$TEST_DIR/file1.txt"
    echo "file2" > "$TEST_DIR/file2.txt"
    echo "file3" > "$TEST_DIR/file3.txt"

    # Verifica criação
    if [[ ! -f "$TEST_DIR/file1.txt" || ! -f "$TEST_DIR/file2.txt" || ! -f "$TEST_DIR/file3.txt" ]]; then
        echo -e "${RED}✗ FAIL${NC}: Falha ao criar ficheiros de teste"
        ((FAIL++))
        return 1
    fi

    # Executa o comando para apagar vários ficheiros de uma só vez
    $SCRIPT delete "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" "$TEST_DIR/file3.txt" > /dev/null 2>&1

    # Verifica se foram removidos do diretório original
    if [[ -f "$TEST_DIR/file1.txt" || -f "$TEST_DIR/file2.txt" || -f "$TEST_DIR/file3.txt" ]]; then
        echo -e "${RED}✗ FAIL${NC}: Um ou mais ficheiros ainda existem no diretório original"
        ((FAIL++))
        return 1
    fi

    # Verifica se os ficheiros estão na reciclagem
    BIN_DIR="$HOME/BernardoTiago_RecycleBin/files"
    BIN_COUNT=$(ls "$BIN_DIR" 2>/dev/null | grep -E 'file[123]' | wc -l)

    if [[ "$BIN_COUNT" -ne 3 ]]; then
        echo -e "${RED}✗ FAIL${NC}: Nem todos os ficheiros foram movidos para a reciclagem"
        ((FAIL++))
        return 1
    fi

    # Se chegou aqui, tudo correu bem
    echo -e "${GREEN}✓ PASS${NC}: Múltiplos ficheiros eliminados com sucesso num único comando"
    ((PASS++))
}

test_empty_recyclebin() {
    echo -e "\n=== Test: Empty Recycle Bin ==="
    setup

    # Cria ficheiros de teste
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    echo "c" > "$TEST_DIR/c.txt"

    # Move para a reciclagem
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" "$TEST_DIR/c.txt" > /dev/null 2>&1

    # Esvazia a reciclagem com --force
    $SCRIPT empty --force > /dev/null 2>&1
    exit_code=$?

    # Verifica o estado final: diretório vazio + metadata limpo + exit code 0
    bin_count=$(ls "$HOME/BernardoTiago_RecycleBin/files" 2>/dev/null | wc -l)
    meta_lines=$(grep -vE '^\s*$' "$HOME/BernardoTiago_RecycleBin/metadata.db" | wc -l)

    if [[ $exit_code -eq 0 && $bin_count -eq 0 && $meta_lines -le 2 ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Recycle Bin esvaziada com sucesso (ficheiros e metadata limpos)"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: Recycle Bin não foi completamente limpa"
        echo "  Exit code: $exit_code"
        echo "  Files remaining: $bin_count"
        echo "  Metadata lines: $meta_lines"
        ((FAIL++))
    fi
}




 
test_list_empty() { 
    echo -e "\n=== Test: List Empty Bin ===" 
    setup 
    $SCRIPT list | grep -q "empty" 
    assert_success "List empty recycle bin" 
} 
 
test_restore_file() { 
    echo -e "\n=== Test: Restore File ===" 
    setup 
    echo "test" > "$TEST_DIR/restore_test.txt" 
    $SCRIPT delete "$TEST_DIR/restore_test.txt" 
     
    # Get file ID from list 
    ID=$($SCRIPT list | grep "restore_test" | awk '{print $1}') 
    $SCRIPT restore "$ID" 
    assert_success "Restore file" 
    [ -f "$TEST_DIR/restore_test.txt" ] && echo "✓ File restored" 
}
 
# Run all tests 
echo "=========================================" 
echo "  Recycle Bin Test Suite" 
echo "=========================================" 
 
reset_metadata
test_initialization
test_delete_file 
test_empty_recyclebin
test_delete_multiple_files
test_list_empty 
test_restore_file 

 
# Add more test functions here 
 
teardown 

echo "=========================================" 
echo "Results: $PASS passed, $FAIL failed" 
echo "========================================="

[ $FAIL -eq 0 ] && exit 0 || exit 1 