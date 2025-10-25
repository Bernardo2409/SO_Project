### Test Case 1: Delete Single File

**Objective:** Verify that a single file can be deleted successfully

**Steps:**
1. Create test file: `echo "test" > test.txt`
2. Run: `./recycle_bin.sh delete test.txt`
3. Verify file is removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin

**Expected Result:**
- File is moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output

**Actual Result:** [Success: 'test.txt' moved to RecycleBin (ID: 1761263107167913373_ku9gjp).]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase1](/BernardoTiago_RecycleBin/screenshots/TestCase1.png)

### Test Case 2: Delete Multiple Files
1. Create multiple test files: `echo "test1" > test1.txt' 'echo "test2" > test2.txt' 'echo "test3" > test3.txt`
2. Run: `./recycle_bin.sh delete test1.txt test2.txt test3.txt`
3. Verify files are removed from current directory
4. Run: `./recycle_bin.sh list`
5. Verify file appears in recycle bin

**Expected Result:**
- Files are moved to ~/.recycle_bin/files/
- Metadata entry is created
- Success message is displayed
- File appears in list output

**Actual Result:** [Success: 'test1.txt' moved to RecycleBin (ID: 1761263749196082664_kpzqph).
Success: 'test2.txt' moved to RecycleBin (ID: 1761263749221991032_jvmsjq).
Success: 'test3.txt' moved to RecycleBin (ID: 1761263749246817961_3ujq7y).]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase2](/BernardoTiago_RecycleBin/screenshots/TestCase2.png)

### Test Case 3: List Empty
1. Make sure you have no files in the recycle_bin
2. Run `./recycle_bin list`

**Expected Result:**
- List empty Recycle Bin

**Actual Result:** [Recycle Bin is empty.]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase3](/BernardoTiago_RecycleBin/screenshots/TestCase3.png)

### Test Case 4: List Content
1. Make sure you have already deleted files
2. Run `./recycle_bin list`

**Expected Result:**
- List of deleted files

**Actual Result** [n file(s) found in Recycle Bin:]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase4](/BernardoTiago_RecycleBin/screenshots/TestCase4.png)

### Test Case 5: Restore file
1. Make sure you have deleted atleast 1 file
2. You wish to restore the file to the last location
3. Run `./recycle_bin restore <fileName>`

**Expected Result:**
- File metadata removed
- File moved to last location
- File was restored successfully

**ActualResult**  [Success: '<fileName>' restored to '<previous location>'.]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase5](/BernardoTiago_RecycleBin/screenshots/TestCase5.png)

### Test Case 6: Restore non-existent file
1. Make sure you have an empty recycle bin or you invent a fake file name to test
2. Try to restore the non-existent file
3. Run `./recycle_bin restore <fakeFileName>`

**Expected Result:**
- File not found
- Unnable to restore

**ActualResult**  [Error: No file found with ID or name 'nonexistentfile.txt'.]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase6](/BernardoTiago_RecycleBin/screenshots/TestCase6.png)

### Test Case 7: Empty entire recycle bin
1. You have 1 or more files in recycle bin
2. You want to permanently delete them
3. Run `./recycle_bin empty`
4. If you want to skip verification run `./recycle_bin empy --force`

**Expected Result:**
- Verification if you want to empty recycle bin (y/s)
- If --force is used, immediatly skip to delete files

**ActualResult**  [Are you sure you want to delete all files? (y/n) 
y
Recycle Bin is empty..]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase7](/BernardoTiago_RecycleBin/screenshots/TestCase7.png)
![TestCase7_force](/BernardoTiago_RecycleBin/screenshots/TestCase7_force.png)

### Test Case 8: Search file
1. You want to check if there's file with specific name
2. You can search by name parts or ID
3. Run `./recycle_bin search <partName>`

**Expected Result:**
- Return a list of files with the name containing <partName>

**ActualResult**  [=== Results ===
1761394034675754155_eh7i84 | test4.txt | /home/tiago/Documents/UA/2ano/1Sem/SistemasOperativos/SO_Project/BernardoTiago_RecycleBin/test4.txt | 2025-10-25 13:07:14 | 6 | ASCII text | 664 | tiago:tiago]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase7](/BernardoTiago_RecycleBin/screenshots/TestCase8.png)

### Test Case 9: Empty Specific File
1. You have a file in recycle bin
2. You want to permanently delete the file
3. You'll need the UniqueID of the file you want to delete, if you are not sure of its ID, run `./recycle_bin search <fileName>`
4. Run `./recycle_bin empty <fileUniqueID>`
5. If you want to skip verification, run `./recycle_bin empty --force <fileUniqueID>`

**Expected Result:**
- Verification if you want to empty recycle bin (y/s)
- If --force is used, immediatly skip to delete the file

**ActualResult**  [Are you sure you want to delete 1761393711552957952_0h3ves? (y/n) 
y
Deleting 1761393711552957952_0h3ves
1761393711552957952_0h3ves successfully deleted.]

**Status:** x Pass ☐ Fail

**Screenshots:** ![TestCase9](/BernardoTiago_RecycleBin/screenshots/TestCase9.png)
![TestCase9_force](/BernardoTiago_RecycleBin/screenshots/TestCase9_force.png)