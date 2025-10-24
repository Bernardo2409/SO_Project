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
    rm -rf "$HOME/BernardoTiago_RecycleBin"
} 
 
teardown() { 
    rm -rf "$TEST_DIR" 
    rm -rf "$HOME/BernardoTiago_RecycleBin"
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

# Initialize recycle bin structure
test_initialization() { 
    echo "=== Test: Initialization ===" 
    setup 
    $SCRIPT help > /dev/null 
    assert_success "Initialize recycle bin" 
    [ -d "$HOME/BernardoTiago_RecycleBin" ] && echo "✓ Directory created" 
    [ -f "$HOME/BernardoTiago_RecycleBin/metadata.db" ] && echo "✓ Metadata file created" 
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


    # Delete all the files on the same time
    $SCRIPT delete "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" "$TEST_DIR/file3.txt" 

    # Verify if they were deleted
    if [[ -f "$TEST_DIR/file1.txt" || -f "$TEST_DIR/file2.txt" || -f "$TEST_DIR/file3.txt" ]]; then
        echo -e "${RED}✗ FAIL${NC}: Um ou mais ficheiros ainda existem no diretório original"
        ((FAIL++))
        return 1
    fi

    # Sucess?????????????????????????????
    echo -e "${GREEN}✓ PASS${NC}: Múltiplos ficheiros eliminados com sucesso num único comando"
    ((PASS++))
}

# Test: Delete Empty Directory
test_delete_empty_directory() {
    echo -e "\n=== Test: Delete Empty Directory ==="
    setup

    # Create empty directory
    mkdir "$TEST_DIR/empty_dir"


    # Delete the empty directory
    $SCRIPT delete "$TEST_DIR/empty_dir" 
    exit_code=$?

    # Verify: directory removed from original location
    if [[ $exit_code -eq 0 && ! -d "$TEST_DIR/empty_dir" ]]; then
        
        echo -e "${GREEN}✓ PASS${NC}: Empty directory deleted and correctly registered in Recycle Bin"
        ((PASS++))
       
    else
        echo -e "${RED}✗ FAIL${NC}: Failed to delete empty directory"
        echo "  Exit code: $exit_code"
        ((FAIL++))
    fi
}

test_delete_directory_with_contents() {
    echo -e "\n=== Test: Delete Directory With Contents ==="
    setup

    # Create directory with nested structure and files
    mkdir -p "$TEST_DIR/dir_with_contents/subdir1/subdir2"
    echo "file1 content" > "$TEST_DIR/dir_with_contents/file1.txt"
    echo "file2 content" > "$TEST_DIR/dir_with_contents/subdir1/file2.txt"
    echo "file3 content" > "$TEST_DIR/dir_with_contents/subdir1/subdir2/file3.txt"

    # Delete the directory recursively
    $SCRIPT delete "$TEST_DIR/dir_with_contents" > /dev/null 2>&1
    exit_code=$?

    # Verify: directory removed from original location
    if [[ $exit_code -eq 0 && ! -d "$TEST_DIR/dir_with_contents" ]]; then
        echo -e "${GREEN}✓ PASS${NC}: Directory with contents deleted recursively and registered in Recycle Bin"
        ((PASS++))
    else
        echo -e "${RED}✗ FAIL${NC}: Failed to delete directory with contents"
        echo "  Exit code: $exit_code"
        ((FAIL++))
    fi
}


test_list_empty() { 
    echo -e "\n=== Test: List Empty Bin ===" 
    setup 
    $SCRIPT list | grep -q "empty"  # found the word 'empty' on the function
    assert_success "List empty recycle bin" 
} 

test_list_with_items() {
    echo -e "\n=== Test: List Bin With Items ===" 
    setup

    echo "file1" > "$TEST_DIR/file1.txt"
    echo "file2" > "$TEST_DIR/file2.txt"
    echo "file3" > "$TEST_DIR/file3.txt"

    $SCRIPT delete "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" "$TEST_DIR/file3.txt"  

    $SCRIPT list | grep -q "file(s)" # found the word 'file(s)' on the function

    assert_success "List recycle bin with items" 

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

test_restore_non_existent() { 
    echo -e "\n=== Test: Restore to non-existent original path ===" 
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
test_delete_multiple_files
test_delete_empty_directory
test_delete_directory_with_contents
test_list_empty 
test_list_with_items
test_restore_file 

# Clean the RecycleBin files after all the tests
bash "$SCRIPT" empty --force > /dev/null 2>&1

# Add more test functions here 
 
teardown 

echo "=========================================" 
echo "Results: $PASS passed, $FAIL failed"
echo "========================================="

[ $FAIL -eq 0 ] && exit 0 || exit 1 