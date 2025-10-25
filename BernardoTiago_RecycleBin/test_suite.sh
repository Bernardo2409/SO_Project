    #!/bin/bash 
    
    # Test Suite for Recycle Bin System 
    
    SCRIPT="./recycle_bin.sh" 
    TEST_DIR="test_data" 
    LOG_FILE="$HOME/BernardoTiago_RecycleBin/recyclebin.log"
    # Ensure log directory exists
    

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


    # Basic Functionality Tests

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
        [ ! -f "$TEST_DIR/test.txt" ] && echo "✓ File removed from original location" 
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
            echo -e "${RED}✗ FAIL${NC}: One or more files in original directory"
            
        fi

        assert_success "Multiple files deleted with sucess"
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
            
            assert_success "Empty directory deleted and correctly registered in Recycle Bin"
        
        else

            assert_fail "Failed to delete empty directory"
            echo "  Exit code: $exit_code"
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
            
            assert_success "Directory with contents deleted recursively and registered in Recycle Bin"
        else
            assert_fail "Failed to delete directory with contents"
            echo "  Exit code: $exit_code"
            ((FAIL++))
        fi
    }


    test_list_empty() { 
        echo -e "\n=== Test: List Empty Bin ===" 
        setup 
        $SCRIPT list | grep -q "Recycle Bin is empty"  # found the word 'empty' on the function
        assert_success "List empty recycle bin" 
    } 

    test_list_with_items() {
        echo -e "\n=== Test: List Bin With Items ===" 
        setup

        # Create files
        echo "file1" > "$TEST_DIR/file1.txt"
        echo "file2" > "$TEST_DIR/file2.txt"
        echo "file3" > "$TEST_DIR/file3.txt"


        # Delete files
        $SCRIPT delete "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" "$TEST_DIR/file3.txt"  

        # Calling list and check the message
        $SCRIPT list | grep -q "file(s) found in Recycle Bin:" 

        assert_success "List recycle bin with items" 

    }
    
    test_restore_file() { 
        echo -e "\n=== Test: Restore File ===" 
        setup 
        # Create file
        echo "test" > "$TEST_DIR/restore_test.txt" 
        # Delete file
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

        # Simulate a non-existent original path for restoration
        NON_EXISTENT_PATH="$TEST_DIR/non_existent_directory/restore_test.txt"
        
        # Attempt to restore the file to the non-existent path
        $SCRIPT restore "$ID" "$NON_EXISTENT_PATH"
        
        # Assert that the restore didn't happen (file should not be restored to non-existent path)
        if [ ! -f "$NON_EXISTENT_PATH" ]; then
            assert_success "File not restored to non-existent path"
        else
            assert_fail "File was restored to a non-existent path"
        fi

    }

    test_empty_recycle() {
        echo -e "\n=== Test: Empty entire recycle bin ==="
        setup

        # Create files
        echo "file1" > "$TEST_DIR/file1.txt"
        echo "file2" > "$TEST_DIR/file2.txt"
        echo "file3" > "$TEST_DIR/file3.txt"

        # Delete all the files 
        $SCRIPT delete "$TEST_DIR/file1.txt" "$TEST_DIR/file2.txt" "$TEST_DIR/file3.txt" 

        # Confirm automatically
        echo "y" | $SCRIPT empty
        
        # Verify if recyclebin is empty
        if [[ ! -f "$RECYCLE_BIN_DIR/file1.txt" && ! -f "$RECYCLE_BIN_DIR/file2.txt" && ! -f "$RECYCLE_BIN_DIR/file3.txt" ]]; then
            assert_success "RecycleBin empty with sucess"

        else
            assert_fail "RecycleBin is not empty"
        fi
    }

    test_search_exist_file() {
        echo -e "\n=== Test: Search for existing file ==="
        setup

        # Create a test file
        echo "test content" > "$TEST_DIR/file1.txt"

        # Delete the file (move it to recycle bin)
        $SCRIPT delete "$TEST_DIR/file1.txt"

        # Get the file ID
        ID=$($SCRIPT list | grep "file1.txt" | awk '{print $1}')

        # Search for the existing file
        RESULT=$($SCRIPT search "file1.txt")

        # Check if the file appears in the search results
        if echo "$RESULT" | grep -q "file1.txt"; then
            assert_success File successfully found via search
        else
            assert_fail File not found in the search
        fi

        # Empty the recycle bin at the end
        empty_recyclebin --force
    }

    test_search_non_exist_file() {
        echo -e "\n=== Test: Search for non-existent file ==="
        setup


        # Search for the non-existent file
        RESULT=$($SCRIPT search "nonfile.txt")

        # Check that the non-existent file is not found in the search results
        if echo "$RESULT" | grep -q "nonfile.txt"; then
            assert_fail "Non-existent file found in the search"
        else
            echo -e "${GREEN}✓ PASS${NC}: Non-existent file was not found in the search"
            assert_success "Non-existent file was NOT found in the search"
        fi

        # Empty the recycle bin at the end
        empty_recyclebin --force

    }

    test_display_help() {
        echo -e "\n=== Test: Display help information ==="
        setup

        # Capture the output of the help command
        HELP_OUTPUT=$($SCRIPT --help)

        # Check if the last line of the help contains "clean: Automatically deletes items"
        if echo "$HELP_OUTPUT" | grep -q "clean:.*Automatically deletes items.*retention period"; then

            echo -e "${GREEN}✓ PASS${NC}: Last line of help information displayed correctly"
            ((PASS++))
        else
            echo -e "${RED}✗ FAIL${NC}: Last line of help information not displayed correctly"
            ((FAIL++))
            return 1
        fi
    }


    ############################################################
    ##################    EDGE CASES     #########################
    ############################################################


    test_delete_non-existent_file() {
        echo -e "\n=== Test: Delete non_existent file ==="
        teardown
        setup

        # Attempt to delete non-existent_file.txt
        $SCRIPT "$TEST_DIR/delete non-existent_file.txt"

        # Assert that there is no file named non-existent_file.txt in metadata
        if grep -q "non-existent_file.txt" "$HOME/BernardoTiago_RecycleBin/metadata.db"; then
            echo "✗ Non-existent file deleted"
            assert_fail "Delete non-existent file"
        else
            echo "✓ Non-existent file not deleted"
            assert_success "Delete non-existent file"
        fi
    }

    test_delete_file_without_permissions() {
        echo -e "\n=== Test: Delete file without permissions ==="
        teardown
        setup

        # Create file, and then remove permissions
        echo "file1" > "$TEST_DIR/file1.txt"
        chmod -rwx "$TEST_DIR/file1.txt"

        # Attempt to delete the file
        $SCRIPT delete "$TEST_DIR/file1.txt"


        # Assert that the file was not deleted (Insufficient permissions)
        if grep -q "file1.txt" "$HOME/BernardoTiago_RecycleBin/metadata.db"; then
            echo "✗ File without permissions was deleted"
            assert_fail "Delete file without permissions"
        else
            echo "✓ File without permissions wasn't deleted"
            assert_success "Delete file without permissions"
        fi
    }

    test_restore_when_original_location_has_same_filename() {
        echo -e "\n=== Test: Restore when original location has same filename ==="
        teardown
        setup

        # Create test file to delete named sameName_file.txt
        echo "file1" > "$TEST_DIR/sameName_file.txt"
        # Delete it
        $SCRIPT delete "$TEST_DIR/sameName_file.txt"
        # Create another file with the same name in the same original location
        echo "file1" > "$TEST_DIR/sameName_file.txt"

        # Attempt to restore deleted file
        $SCRIPT restore sameName_file.txt

        # Capture the restored file name (it should have a suffix like "_restored_XXXX")
        restored_file=$(ls "$TEST_DIR" | grep "sameName_file.txt_restored")


        # Verify if the file was restored (isn't in the metadata no more) with a different name
        if grep -q "sameName_file.txt" "$HOME/BernardoTiago_RecycleBin/metadata.db"; then
            echo "✗ File was not restored"
            assert_fail "Restore when original location has same filename"
        else
            echo "✓ File was restored"
            assert_success "Restore when original location has same filename"
        fi
    }

    test_restore_with_unexistent_id() {
        echo -e "\n=== Test: Restore with ID that doesn't exist ==="
        teardown
        setup

        # Metadata file is empty now, so there are no file IDs
        # Attempt to restore a non-existent ID
        $SCRIPT restore 0123456789_nreal

        # Check if no file was restored
        restored_file=$(ls "$TEST_DIR")

        if [[ -z "$restored_file" ]]; then
            echo "✓ File was not restored"
            assert_success "Restore with ID that doesn't exist"
        else
            echo "✗ Some file was restored"
            assert_fail "Restore with ID that doesn't exist"
        fi
    }

    test_handle_filenames_wSpaces() {
        echo -e "\n=== Test: Handle filenames with spaces ==="

        teardown
        setup

        # Create filename with special characters in TEST_DIR
        echo "file name with spaces" > "$TEST_DIR/file name with spaces.txt"

        # Try to delete the file with spaces in the filename
        $SCRIPT delete "$TEST_DIR/file name with spaces.txt"

        # List the files in the recycle bin to confirm deletion
        deleted_files=$($SCRIPT list)


        # Attempt to restore the file with spaces in the filename
        $SCRIPT restore "file name with spaces.txt"

        # Capture the restored file name
        restored_file=$(ls "$TEST_DIR" | grep "file name with spaces.txt")

        # Verify if the file was restored (check TEST_DIR for restored file)
        if [[ -n "$restored_file" ]]; then
            echo "✓ File with spaces was restored successfully as $restored_file"
            assert_success "Restore file with spaces"
        else
            echo "✗ File was not restored"
            assert_fail "Restore file with spaces"
        fi
    }

    test_handle_filenames_wSpecialChars() {
        echo -e "\n=== Test: Handle filenames with special characters ==="

        teardown
        setup

        # Create filename with special characters in TEST_DIR
        FILE_NAME="!@#$%^&*().txt"
        echo "test content" > "$TEST_DIR/$FILE_NAME"

        # Try to delete the file with special characters in the filename
        $SCRIPT delete "$TEST_DIR/$FILE_NAME"

        # List the files in the recycle bin to confirm deletion
        deleted_files=$($SCRIPT list)

        # Escape special characters for grep to handle them correctly
        ESCAPED_FILE_NAME=$(echo "$FILE_NAME" | sed 's/[]\/$*.^[]/\\&/g')

        # Ensure the file is in the recycle bin by checking the list of deleted files
        if echo "$deleted_files" | grep -q "$ESCAPED_FILE_NAME"; then
            echo -e "${GREEN}✓ PASS${NC}: File with special characters deleted successfully"
        else
            echo -e "${RED}✗ FAIL${NC}: File with special characters not found in the recycle bin"
        fi

        # Attempt to restore the file with special characters in the filename
        $SCRIPT restore "$FILE_NAME"
        
        # The file should be restored to its original path or a default location.
        # Let's assume it is restored back to the TEST_DIR, as that's where the original file was.
        restored_file="$TEST_DIR/$FILE_NAME"

        # Verify if the file was restored (check TEST_DIR for restored file)
        if [[ -f "$restored_file" ]]; then
            echo -e "${GREEN}✓ PASS${NC}: File with special characters was restored successfully as $restored_file"
            assert_success "Restore file with special characters"
        else
            echo -e "${RED}✗ FAIL${NC}: File was not restored"
            assert_fail "Restore file with special characters"
        fi
    }


    test_handle_long_filenames() {
    echo -e "\n=== Test: Handle very long filenames (255+ characters) ==="

    teardown
    setup

    # Garante diretório e log global existem (mas não os usamos para a verificação)
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"

    # Nome >255
    local base_name
    base_name=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 260)
    local LONG_FILENAME="${base_name}.txt"
    local full_path="$TEST_DIR/$LONG_FILENAME"

    # Log temporário apenas para este teste
    local TMP_LOG
    TMP_LOG="$(mktemp)"

    echo "Attempting to create long filename..." | tee -a "$TMP_LOG" >> "$LOG_FILE"

    # Captura **apenas** o erro desta tentativa
    create_err="$({ echo 'test content for long file' > "$full_path"; } 2>&1)"
    # escreve no log temporário e no global (se quiseres manter histórico)
    { echo "$create_err" | tee -a "$TMP_LOG" >> "$LOG_FILE"; } >/dev/null

    # Mensagens possíveis consoante locale/kernel
    if echo "$create_err" | grep -Eq 'Nome de ficheiro muito grande|File name too long|ENAMETOOLONG'; then
        assert_success "System correctly refused to create filename >255 chars"
        rm -f "$TMP_LOG"
        return 0
    fi

    # Se não criou e não houve ENAMETOOLONG
    if [[ ! -f "$full_path" ]]; then
        assert_fail "File creation failed for an unknown reason"
        rm -f "$TMP_LOG"
        return 1
    fi

    # Ambiente permitiu criar (raro), segue como “tolerado”
    echo "Warning: system allowed a filename >255 chars; continuing extended checks..." | tee -a "$TMP_LOG" >> "$LOG_FILE"
    assert_success "Environment tolerated long filename (acceptable for this test)"
    rm -f "$TMP_LOG"
}




    test_handle_large_files() {
    echo -e "\n=== Test: Handle very large files ==="

    teardown
    setup

    local LARGE_FILE="$TEST_DIR/large_test_file.bin"
    local FILE_SIZE_MB=100  # Adjust as needed
    local BLOCK_SIZE=1M

    echo "Creating a ${FILE_SIZE_MB}MB test file..."
    dd if=/dev/zero of="$LARGE_FILE" bs=$BLOCK_SIZE count=$FILE_SIZE_MB status=none
    local create_exit=$?

    # If creation failed, mark as fail immediately
    if [[ $create_exit -ne 0 || ! -f "$LARGE_FILE" ]]; then
        assert_fail "Failed to create large test file"
        return 1
    fi

    # Delete the large file (move to Recycle Bin)
    echo "Deleting large file..."
    $SCRIPT delete "$LARGE_FILE" > /dev/null 2>&1
    local delete_exit=$?

    # Restore the large file
    echo "Restoring large file..."
    $SCRIPT restore "large_test_file.bin" > /dev/null 2>&1
    local restore_exit=$?

    # Verify that the restored file exists and has the expected size
    local restored_size=$(stat -c%s "$LARGE_FILE" 2>/dev/null)
    local expected_size=$((FILE_SIZE_MB * 1024 * 1024))

    if [[ $delete_exit -eq 0 && $restore_exit -eq 0 && $restored_size -eq $expected_size ]]; then
        assert_success "Large file successfully deleted, restored, and verified"
    else
        assert_fail "Large file handling failed (delete/restore/size mismatch)"
    fi
}



    test_handle_symb_links() {
    echo -e "\n=== Test: Handle symbolic links ==="

    teardown
    setup

    # Create a real file and a symbolic link to it
    local TARGET_FILE="$TEST_DIR/real_file.txt"
    local SYMLINK_FILE="$TEST_DIR/symlink_to_real.txt"

    echo "original content" > "$TARGET_FILE"
    ln -s "$TARGET_FILE" "$SYMLINK_FILE"

    # Try to delete the symbolic link (should be refused by delete_file)
    $SCRIPT delete "$SYMLINK_FILE" > "$LOG_FILE" 2>&1
    local delete_exit=$?

    # Check if the script correctly refused to delete the symlink
    if grep -q "Symbolic" "$LOG_FILE" || grep -q "Error" "$LOG_FILE"; then
        assert_success "Symbolic links correctly rejected from deletion"
    else
        assert_fail "Symbolic link was not properly handled"
    fi
}

test_handle_hidden_files() {
    echo -e "\n=== Test: Handle hidden files (starting with .) ==="

    teardown
    setup

    # Create a hidden file
    local HIDDEN_FILE="$TEST_DIR/.hidden_test_file.txt"
    echo "secret content" > "$HIDDEN_FILE"

    # Delete the hidden file
    $SCRIPT delete "$HIDDEN_FILE" > "$LOG_FILE" 2>&1
    local delete_exit=$?

    # Restore the hidden file
    $SCRIPT restore ".hidden_test_file.txt" > "$LOG_FILE" 2>&1
    local restore_exit=$?

    # Check if the hidden file was restored correctly
    if [[ $delete_exit -eq 0 && $restore_exit -eq 0 && -f "$HIDDEN_FILE" ]]; then
        assert_success "Hidden file successfully deleted and restored"
    else
        assert_fail "Failed to handle hidden file (delete/restore issue)"
    fi
}

test_delete_files_from_different_directories() {
    echo -e "\n=== Test: Delete files from different directories ==="

    teardown
    setup

    # Create multiple directories and files
    mkdir -p "$TEST_DIR/dirA" "$TEST_DIR/dirB" "$TEST_DIR/dirC"
    echo "File A content" > "$TEST_DIR/dirA/fileA.txt"
    echo "File B content" > "$TEST_DIR/dirB/fileB.txt"
    echo "File C content" > "$TEST_DIR/dirC/fileC.txt"

    # Delete files from different directories in one command
    $SCRIPT delete "$TEST_DIR/dirA/fileA.txt" "$TEST_DIR/dirB/fileB.txt" "$TEST_DIR/dirC/fileC.txt" > "$LOG_FILE" 2>&1
    local delete_exit=$?

    # Check if all were deleted from original directories
    if [[ $delete_exit -eq 0 && ! -f "$TEST_DIR/dirA/fileA.txt" && ! -f "$TEST_DIR/dirB/fileB.txt" && ! -f "$TEST_DIR/dirC/fileC.txt" ]]; then
        assert_success "Files from different directories deleted successfully in a single command"
    else
        assert_fail "Failed to delete files from multiple directories"
    fi
}

test_restore_to_readonly_directory() {
    echo -e "\n=== Test: Restore files to read-only directories ==="

    teardown
    setup

    # Create a read-only directory and a file inside it
    mkdir -p "$TEST_DIR/readonly_dir"
    echo "protected content" > "$TEST_DIR/readonly_dir/protected.txt"

    # Delete the file (move to recycle bin)
    $SCRIPT delete "$TEST_DIR/readonly_dir/protected.txt" > "$LOG_FILE" 2>&1

    # Make the directory read-only (no write permission)
    chmod 555 "$TEST_DIR/readonly_dir"

    # Try to restore the deleted file (should fail)
    $SCRIPT restore "protected.txt" > "$LOG_FILE" 2>&1
    local restore_exit=$?

    # Revert permissions for cleanup
    chmod 755 "$TEST_DIR/readonly_dir"

    # Check if restore was prevented (expected behavior)
    if [[ $restore_exit -ne 0 && ! -f "$TEST_DIR/readonly_dir/protected.txt" ]]; then
        assert_success "Restore correctly prevented in read-only directory"
    else
        assert_fail "Restore succeeded unexpectedly in read-only directory"
    fi
}

    #ERROR HANDLING
    test_invalid_command() {
    echo -e "\n=== Test: Invalid command line arguments ==="

    teardown
    setup

    # Run the script with an invalid command
    $SCRIPT invalid_command > "$LOG_FILE" 2>&1
    local exit_code=$?

    # Expect non-zero exit and an error message
    if [[ $exit_code -ne 0 && $(grep -ci "use" "$LOG_FILE") -gt 0 ]]; then
        assert_success "Invalid command handled gracefully with an error message"
    else
        assert_fail "Script did not handle invalid command correctly"
    fi
}

    test_missing_required_parameters() {
    echo -e "\n=== Test: Missing required parameters ==="

    teardown
    setup

    # Call delete without arguments (should fail and print usage)
    $SCRIPT delete > "$LOG_FILE" 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 0 && $(grep -ci "usage" "$LOG_FILE") -gt 0 ]]; then
        assert_success "Handled missing parameters correctly (usage message displayed)"
    else
        assert_fail "Did not handle missing parameters as expected"
    fi
}

    test_corrupted_metadata_file() {
    echo -e "\n=== Test: Corrupted metadata file ==="

    teardown
    setup

    # Create a corrupted metadata file
    mkdir -p "$HOME/BernardoTiago_RecycleBin"
    echo "corrupted content without headers or commas" > "$HOME/BernardoTiago_RecycleBin/metadata.db"

    # Attempt to list recycle bin contents
    $SCRIPT list > "$LOG_FILE" 2>&1
    local exit_code=$?

    # Expect graceful failure, not a crash
    if [[ $exit_code -ne 0 && $(grep -ci "error" "$LOG_FILE") -gt 0 ]]; then
        assert_success "Corrupted metadata file handled gracefully"
    else
        assert_fail "Script did not handle corrupted metadata file correctly"
    fi
}

    test_insufficient_disk_space() {
    echo -e "\n=== Test: Insufficient disk space ==="

    teardown
    setup

    # Create a test file
    echo "some data" > "$TEST_DIR/full_disk.txt"

    # Mock mv to simulate 'No space left on device'
    mv_original=$(which mv)
    mv() { echo "mv: cannot move file: No space left on device" >&2; return 1; }

    # Try to delete (should fail gracefully)
    $SCRIPT delete "$TEST_DIR/full_disk.txt" > "$LOG_FILE" 2>&1
    local exit_code=$?

    # Restore mv
    unset -f mv

    if [[ $exit_code -ne 0 && $(grep -ci "no space left" "$LOG_FILE") -gt 0 ]]; then
        assert_success "Handled insufficient disk space gracefully"
    else
        assert_fail "Failed to handle insufficient disk space correctly"
    fi
}

    test_permission_denied_errors() {
    echo -e "\n=== Test: Permission denied errors ==="

    teardown
    setup

    # Create file and remove permissions
    echo "secret data" > "$TEST_DIR/locked.txt"
    chmod 000 "$TEST_DIR/locked.txt"

    # Try to delete it (should fail)
    $SCRIPT delete "$TEST_DIR/locked.txt" > "$LOG_FILE" 2>&1
    local exit_code=$?

    chmod 755 "$TEST_DIR/locked.txt"  # reset for cleanup

    if [[ $exit_code -ne 0 && $(grep -ci "insufficient permissions" "$LOG_FILE") -gt 0 ]]; then
        assert_success "Permission denied handled correctly"
    else
        assert_fail "Permission denied not handled as expected"
    fi
}

    test_delete_recycle_bin_itself() {
    echo -e "\n=== Test: Attempting to delete recycle bin itself ==="

    teardown
    setup

    # Initialize recycle bin
    $SCRIPT help > /dev/null
    local bin_path="$HOME/BernardoTiago_RecycleBin"

    # Try to delete the recycle bin folder itself
    $SCRIPT delete "$bin_path" > "$LOG_FILE" 2>&1
    local exit_code=$?

    if [[ $exit_code -ne 0 && $(grep -ci "cannot delete the recycle bin" "$LOG_FILE") -gt 0 ]]; then
        assert_success "Attempt to delete recycle bin handled correctly"
    else
        assert_fail "Recycle bin deletion not properly blocked"
    fi
}

    test_concurrent_operations() {
    echo -e "\n=== Test: Concurrent operations (two instances) ==="

    teardown
    setup

    # Create two files
    echo "file one" > "$TEST_DIR/file1.txt"
    echo "file two" > "$TEST_DIR/file2.txt"

    # Run two delete operations in background
    ($SCRIPT delete "$TEST_DIR/file1.txt" > /dev/null 2>&1) &
    ($SCRIPT delete "$TEST_DIR/file2.txt" > /dev/null 2>&1) &
    wait

    # Verify that both were deleted safely
    if [[ ! -f "$TEST_DIR/file1.txt" && ! -f "$TEST_DIR/file2.txt" ]]; then
        assert_success "Concurrent delete operations handled safely"
    else
        assert_fail "Concurrent operations caused conflict or data loss"
    fi
}

    test_delete_100_files() {
    echo -e "\n=== Test: Delete 100+ files ==="

    teardown
    setup

    # Create 100 test files
    echo -e "${GREEN}Creating 101 files... ${NC}"
    for i in $(seq 1 101); do
        echo "data $i" > "$TEST_DIR/file_$i.txt"
    done

    # Delete all files in one go
    $SCRIPT delete "$TEST_DIR"/*.txt > "$LOG_FILE" 2>&1
    local exit_code=$?

    # Check if all were deleted
    local remaining=$(ls "$TEST_DIR" | wc -l)
    if [[ $exit_code -eq 0 && $remaining -eq 0 ]]; then
        assert_success "Successfully deleted 100+ files"
    else
        assert_fail "Failed to delete 100+ files correctly"
    fi
}

    test_list_recyclebin_100_items() {
    echo -e "\n=== Test: List recycle bin with 100+ items ==="

    teardown
    setup

    # Create and delete 100+ files
    echo -e "${GREEN}Creating 101 files...${NC}"
    for i in $(seq 1 101); do
        echo "item $i" > "$TEST_DIR/item_$i.txt"
    done
    $SCRIPT delete "$TEST_DIR"/*.txt > /dev/null 2>&1

    # List the recycle bin
    LIST_OUTPUT=$($SCRIPT list --detailed | grep -c "item_")

    # Expect 100+ entries in the list
    if (( LIST_OUTPUT >= 100 )); then
        assert_success "Recycle bin listed 100+ items successfully"
    else
        assert_fail "Recycle bin did not show all 100+ items"
    fi
}

    test_search_in_large_metadata() {
    echo -e "\n=== Test: Search in large metadata file ==="

    teardown
    setup

    # Populate recycle bin with 100+ entries
    for i in $(seq 1 120); do
        echo "searchable file $i" > "$TEST_DIR/search_file_$i.txt"
    done
    $SCRIPT delete "$TEST_DIR"/*.txt > /dev/null 2>&1

    # Pick a random file to search for
    target="search_file_57.txt"

    # Perform the search
    SEARCH_OUTPUT=$($SCRIPT search "$target")

    if echo "$SEARCH_OUTPUT" | grep -q "$target"; then
        assert_success "Search works correctly with large metadata (100+ entries)"
    else
        assert_fail "Search failed in large metadata file"
    fi
}

    test_restore_from_large_bin() {
    echo -e "\n=== Test: Restore from bin with many items ==="

    teardown
    setup

    # Create and delete 101 files
    echo -e "${GREEN}Creating 101 files...${NC}"
    for i in $(seq 1 101); do
        echo "restore data $i" > "$TEST_DIR/restore_file_$i.txt"
    done
    $SCRIPT delete "$TEST_DIR"/*.txt > /dev/null 2>&1

    # Pick one random file to restore
    target="restore_file_42.txt"

    # Restore by filename
    $SCRIPT restore "$target" > "$LOG_FILE" 2>&1
    local exit_code=$?

    # Check if the file is restored back
    if [[ $exit_code -eq 0 && -f "$TEST_DIR/$target" ]]; then
        assert_success "Restored file correctly from large bin (100+ items)"
    else
        assert_fail "Failed to restore file from large bin"
    fi
}



    
    # Run all tests 
    echo "=========================================" 
    echo "  Recycle Bin Test Suite" 
    echo "=========================================" 

    #Basic Funtionality Tests (13)

    test_initialization
    test_delete_file 
    test_delete_multiple_files
    test_delete_empty_directory
    test_delete_directory_with_contents
    test_list_empty 
    test_list_with_items
    test_restore_file 
    test_restore_non_existent
    test_empty_recycle
    test_search_exist_file
    test_search_non_exist_file
    test_display_help


    #Edge Cases (12)
    #test_delete_non-existent_file
    #test_delete_file_without_permissions
    #test_restore_when_original_location_has_same_filename
    #test_restore_with_unexistent_id
    #test_handle_filenames_wSpaces
    #test_handle_filenames_wSpecialChars
    #test_handle_long_filenames 
    #test_handle_large_files
    #test_handle_symb_links
    #test_handle_hidden_files
    #test_delete_files_from_different_directories
    #test_restore_to_readonly_directory


    #Erros Handling (11)
    #test_invalid_command
    #test_missing_required_parameters
    #test_corrupted_metadata_file
    #test_insufficient_disk_space
    #test_permission_denied_errors
    #test_delete_recycle_bin_itself
    #test_concurrent_operations
    #test_delete_100_files
    #test_list_recyclebin_100_items
    #test_search_in_large_metadata
    #test_restore_from_large_bin

    # Clean the RecycleBin files after all the tests
    bash "$SCRIPT" empty --force > /dev/null 2>&1

    # Add more test functions here 
    
    teardown 

    echo "=========================================" 
    echo "Results: $PASS passed, $FAIL failed"
    echo "========================================="

    [ $FAIL -eq 0 ] && exit 0 || exit 1 