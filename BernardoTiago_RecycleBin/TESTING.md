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
**Screenshots:** ![TestCase1](/BernardoTiago_RecycleBin/screenshots/TestCase2.png)
