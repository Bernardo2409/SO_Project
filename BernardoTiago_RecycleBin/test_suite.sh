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

    # Create test files
    echo "file1" > "$TEST_DIR/file1.txt"
    echo "file2" > "$TEST_DIR/file2.txt"
    echo "file3" > "$TEST_DIR/file3.txt"

    # Verify if they were created
    if [[ ! -f "$TEST_DIR/file1.txt" || ! -f "$TEST_DIR/file2.txt" || ! -f "$TEST_DIR/file3.txt" ]]; then
        echo -e "${RED}✗ FAIL${NC}: Falha ao criar ficheiros de teste"
        ((FAIL++))
        return 1
    fi

    # Delete all the files on the same time
    $SCRIPT delete "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" "$TEST_DIR/file3.txt" > /dev/null 2>&1

    # Verify if they were deleted
    if [[ -f "$TEST_DIR/file1.txt" || -f "$TEST_DIR/file2.txt" || -f "$TEST_DIR/file3.txt" ]]; then
        echo -e "${RED}✗ FAIL${NC}: Um ou mais ficheiros ainda existem no diretório original"
        ((FAIL++))
        return 1
    fi

    # Verify if the files are in metadata
    BIN_COUNT=$(grep -cE ",file[123]\.txt," "$HOME/BernardoTiago_RecycleBin/metadata.db")

    if [[ "$BIN_COUNT" -eq 3 ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Todos os ficheiros foram movidos e registados na reciclagem"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: Esperava 3 ficheiros na reciclagem, mas encontrei ${BIN_COUNT}"
        ((FAIL++))
    fi


    # Sucess?????????????????????????????
    echo -e "${GREEN}✓ PASS${NC}: Múltiplos ficheiros eliminados com sucesso num único comando"
    ((PASS++))
}

test_empty_recyclebin() {
    echo -e "\n=== Test: Empty Recycle Bin ==="
    setup

    # Create test files
    echo "a" > "$TEST_DIR/a.txt"
    echo "b" > "$TEST_DIR/b.txt"
    echo "c" > "$TEST_DIR/c.txt"

    # Move to RecycleBin
    $SCRIPT delete "$TEST_DIR/a.txt" "$TEST_DIR/b.txt" "$TEST_DIR/c.txt" > /dev/null 2>&1

    # Clean up the RecycleBin with --force
    $SCRIPT empty --force > /dev/null 2>&1
    exit_code=$?

    # Verify: empyt directory + clean metadata + exit code 0
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
# Test: Delete Empty Directory
test_delete_empty_directory() {
    echo -e "\n=== Test: Delete Empty Directory ==="
    setup

    # Create empty directory
    mkdir "$TEST_DIR/empty_dir"

    # Verify directory was created and is empty
    if [[ ! -d "$TEST_DIR/empty_dir" || -n "$(ls -A "$TEST_DIR/empty_dir")" ]]; then
        echo -e "${RED}✗ FAIL${NC}: Failed to create empty directory"
        ((FAIL++))
        return 1
    fi

    # Delete the empty directory
    $SCRIPT delete "$TEST_DIR/empty_dir" > /dev/null 2>&1
    exit_code=$?

    # Verify: directory removed from original location
    if [[ $exit_code -eq 0 && ! -d "$TEST_DIR/empty_dir" ]]; then
        # Verify if the directory is in metadata (should have type "directory")
        dir_entry=$(grep -E ",empty_dir," "$HOME/BernardoTiago_RecycleBin/metadata.db")
        if [[ -n "$dir_entry" && $(echo "$dir_entry" | cut -d',' -f6) == *"directory"* ]]; then
            echo -e "${GREEN}✓ PASS${NC}: Empty directory deleted and correctly registered in Recycle Bin"
            ((PASS++))
        else
            echo -e "${RED}✗ FAIL${NC}: Directory not properly registered in metadata"
            ((FAIL++))
        fi
    else
        echo -e "${RED}✗ FAIL${NC}: Failed to delete empty directory"
        echo "  Exit code: $exit_code"
        ((FAIL++))
    fi
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
test_delete_empty_directory 

# Clean the RecycleBin files after all the tests
bash "$SCRIPT" empty --force > /dev/null 2>&1

# Add more test functions here 
 
teardown 

echo "=========================================" 
echo "Results: $PASS passed, $FAIL failed"
echo "========================================="

[ $FAIL -eq 0 ] && exit 0 || exit 1 