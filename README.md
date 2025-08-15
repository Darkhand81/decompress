# Decompress

**A smart, safe decompression tool that handles any compressed file without the hassle!**

> Hmm... Was it `tar -xzf` for tar files? Or is that for .gzip? Am I doing this right for this .zip file? What about .xz files? And wait, is this actually a real archive or just a text file someone renamed?

Who cares! Just run `decompress filename.whatever` and your file will be safely extracted with intelligent defaults and security checks. No more memorizing arcane command-line switches!

## Features

### **Smart Extraction**
- **Auto-detection**: Supports 12+ archive formats with automatic tool detection
- **File verification**: Uses the `file` command to verify archives are actually what they claim to be
- **Dependency checking**: Automatically checks if required tools are installed before attempting extraction

###️ **Safety First**
- **Security scanning**: Detects potentially malicious archives with path traversal attacks (`../../../etc/passwd`)
- **Content preview**: Shows what will be extracted before doing it
- **Clutter prevention**: Warns when multiple items would be created in current directory
- **Interactive choices**: Lets you decide how to handle potentially messy extractions

### **User-Friendly**
- **Destination control**: Extract to any directory with `decompress archive.tar.gz ./target_folder`
- **Auto-creation**: Creates destination directories if they don't exist
- **Smart cleanup**: Optional removal of source files after successful extraction
- **Clear feedback**: Detailed progress and error messages

## Supported Formats

| Format | Extensions | Tool Required |
|--------|------------|---------------|
| **Tar** | `.tar` | `tar` |
| **Gzip Tar** | `.tar.gz`, `.tgz` | `tar` |
| **Bzip2 Tar** | `.tar.bz2`, `.tbz2` | `tar` |
| **XZ Tar** | `.tar.xz` | `tar` |
| **Gzip** | `.gz` | `gunzip` |
| **Bzip2** | `.bz2` | `bunzip2` |
| **XZ** | `.xz` | `xz` |
| **Zip** | `.zip` | `unzip` |
| **RAR** | `.rar` | `unrar` or `rar` |
| **7-Zip** | `.7z` | `7z` |
| **Compress** | `.Z` | `uncompress` |

## Usage

### Basic Usage
```bash
# Extract to current directory
decompress archive.tar.gz

# Extract to specific directory
decompress archive.zip ./extracted_files

# Extract to new directory (will be created)
decompress data.7z /tmp/my_data
```

### Examples

**Simple extraction:**
```bash
$ decompress photos.zip
File type verified: Zip archive data, at least v2.0 to extract
Previewing archive contents...
Archive contains 1 top-level items:
photos/
Extracting 'photos.zip'...
Extraction completed successfully
Do you want to remove the original file (photos.zip) [Y/n]? y
Original file 'photos.zip' removed
```

**Multi-item archive with safety prompt:**
```bash
$ decompress messy-archive.tar.gz
File type verified: gzip compressed data, tar archive
Previewing archive contents...
Archive contains 8 top-level items:
README.md
src/
docs/
config.ini
...

This will create multiple items in the current directory.
Options:
1) Continue extraction to current directory
2) Extract to a new subdirectory
3) Cancel extraction
Choose [1/2/3]: 2
Enter subdirectory name (will be created): my_project
Created directory 'my_project'
Extracting 'messy-archive.tar.gz'...
Extraction completed successfully
Contents extracted to: my_project
```

**Security warning example:**
```bash
$ decompress suspicious.tar
File type verified: tar archive
Previewing archive contents...
WARNING: Archive contains paths with '..' which could extract outside the target directory
Suspicious paths found:
../../../etc/passwd
../../config/secrets
Do you want to continue anyway? [y/N]: n
Extraction aborted
```

##️ Installation

### Quick Install
```bash
# Make executable and install system-wide
chmod +x decompress
sudo cp decompress /usr/local/bin/

# Now you can run it from anywhere!
decompress ~/Downloads/archive.tar.gz
```

### Dependencies
The script will automatically check for required tools. Install missing ones:

**Ubuntu/Debian:**
```bash
sudo apt install tar gzip bzip2 xz-utils unzip unrar p7zip-full
```

**CentOS/RHEL/Fedora:**
```bash
sudo dnf install tar gzip bzip2 xz unzip unrar p7zip
```

**macOS (with Homebrew):**
```bash
brew install gnu-tar gzip bzip2 xz unzip unrar p7zip
```

## Advanced Features

### File Type Verification
The script uses the `file` command to verify that archives match their extensions:
- Prevents extraction of files with misleading extensions
- Catches corrupted or incomplete downloads
- Adds security against disguised malicious files

### Intelligent Destination Handling
- **Auto-creation**: Destination directories are created if they don't exist
- **Validation**: Ensures destination is writable and not a file
- **Path safety**: Validates destination paths for security

### Interactive Safety Checks
- **Path traversal detection**: Warns about `../` paths that could extract outside target
- **Multi-item prevention**: Prevents accidentally cluttering current directory
- **User choice**: Always gives you control over potentially risky operations

## Troubleshooting

**"Command not found" errors:**
```bash
ERROR: 'unrar' is not installed or not in PATH
Please install 'unrar' to use this script
```
Install the missing tool using your package manager.

**"File type mismatch" errors:**
```bash
ERROR: File type mismatch for 'fake.tar.gz'
Expected: gzip compressed.*tar archive
Detected: ASCII text
```
The file extension doesn't match the actual file type. Check if the file was corrupted during download or incorrectly named.

**Permission errors:**
```bash
ERROR: Destination directory './restricted' is not writable
```
Ensure you have write permissions to the destination directory.

## License

This script is provided as-is for educational and practical use. Feel free to modify and distribute!

## Contributing

Found a bug or want to add support for another archive format? Pull requests welcome!
