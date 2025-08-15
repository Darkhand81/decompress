#!/bin/bash

# Function to check if a command exists
check_command() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "ERROR: '$1' is not installed or not in PATH"
        echo "Please install '$1' to use this script"
        exit 1
    fi
}

# Function to verify file type using the file command
verify_file_type() {
    local filepath="$1"
    local expected_pattern="$2"
    
    # Get file type information
    local file_info
    file_info=$(file -b "$filepath" 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo "ERROR: Unable to determine file type for '$filepath'"
        exit 1
    fi
    
    # Check if the file matches expected pattern (case-insensitive)
    if ! echo "$file_info" | grep -qi "$expected_pattern"; then
        echo "ERROR: File type mismatch for '$filepath'"
        echo "Expected: $expected_pattern"
        echo "Detected: $file_info"
        echo "The file extension may be incorrect or the file may be corrupted"
        exit 1
    fi
    
    echo "File type verified: $file_info"
}

# Function to preview archive contents for directory clutter check
preview_and_check_archive() {
    local filepath="$1"
    local dest_dir="$2"
    
    echo "Previewing archive contents..."
    
    case "$filepath" in
        *.tar.bz2|*.tar.gz|*.tar.xz|*.tar|*.tbz2|*.tgz)
            local contents
            contents=$(tar -tf "$filepath" 2>/dev/null | head -20)
            if [ $? -ne 0 ]; then
                echo "ERROR: Unable to preview tar archive contents"
                exit 1
            fi
            ;;
        *.zip)
            local contents
            contents=$(unzip -l "$filepath" 2>/dev/null | tail -n +4 | head -n -2 | awk '{print $4}' | head -20)
            if [ $? -ne 0 ]; then
                echo "ERROR: Unable to preview zip archive contents"
                exit 1
            fi
            ;;
        *.rar)
            local contents
            if command -v unrar >/dev/null 2>&1; then
                contents=$(unrar lb "$filepath" 2>/dev/null | head -20)
            else
                contents=$(rar lb "$filepath" 2>/dev/null | head -20)
            fi
            if [ $? -ne 0 ]; then
                echo "ERROR: Unable to preview rar archive contents"
                exit 1
            fi
            ;;
        *.7z)
            local contents
            contents=$(7z l "$filepath" 2>/dev/null | grep -E "^[0-9]" | awk '{print $6}' | head -20)
            if [ $? -ne 0 ]; then
                echo "ERROR: Unable to preview 7z archive contents"
                exit 1
            fi
            ;;
        *)
            # Single file archives (gz, bz2, xz, Z) - no preview needed
            return 0
            ;;
    esac
    
    # Check for suspicious paths
    if echo "$contents" | grep -q "\.\."; then
        echo "WARNING: Archive contains paths with '..' which could extract outside the target directory"
        echo "Suspicious paths found:"
        echo "$contents" | grep "\.\." | head -5
        echo -n "Do you want to continue anyway? [y/N]: "
        read -r response
        case "$response" in
            [Yy]* ) ;;
            * ) echo "Extraction aborted"; exit 1 ;;
        esac
    fi
    
    # Count top-level items
    local top_level_count
    top_level_count=$(echo "$contents" | grep -v "^$" | sed 's|/.*||' | sort | uniq | wc -l)
    
    if [ -z "$dest_dir" ] && [ "$top_level_count" -gt 1 ]; then
        echo "Archive contains $top_level_count top-level items:"
        echo "$contents" | grep -v "^$" | sed 's|/.*||' | sort | uniq | head -10
        if [ "$top_level_count" -gt 10 ]; then
            echo "... and $((top_level_count - 10)) more"
        fi
        echo ""
        echo "This will create multiple items in the current directory."
        echo "Options:"
        echo "1) Continue extraction to current directory"
        echo "2) Extract to a new subdirectory"
        echo "3) Cancel extraction"
        echo -n "Choose [1/2/3]: "
        read -r choice
        
        case "$choice" in
            1)
                echo "Extracting to current directory..."
                ;;
            2)
                echo -n "Enter subdirectory name (will be created): "
                read -r subdir
                if [ -z "$subdir" ]; then
                    echo "ERROR: No directory name provided"
                    exit 1
                fi
                mkdir -p "$subdir"
                if [ $? -ne 0 ]; then
                    echo "ERROR: Unable to create directory '$subdir'"
                    exit 1
                fi
                echo "Created directory '$subdir'"
                DEST_DIR="$subdir"
                ;;
            *)
                echo "Extraction cancelled"
                exit 0
                ;;
        esac
    fi
}

# Function to extract archive to specified destination
extract_archive() {
    local filepath="$1"
    local dest_dir="$2"
    local extract_opts=""
    
    if [ -n "$dest_dir" ]; then
        extract_opts="-C \"$dest_dir\""
    fi
    
    case "$filepath" in
        *.tar.bz2)  
            if [ -n "$dest_dir" ]; then
                tar xjf "$filepath" -C "$dest_dir"
            else
                tar xjf "$filepath"
            fi
            ;;
        *.tar.gz)   
            if [ -n "$dest_dir" ]; then
                tar xzf "$filepath" -C "$dest_dir"
            else
                tar xzf "$filepath"
            fi
            ;;
        *.tar.xz)   
            if [ -n "$dest_dir" ]; then
                tar xJf "$filepath" -C "$dest_dir"
            else
                tar xJf "$filepath"
            fi
            ;;
        *.bz2)      
            if [ -n "$dest_dir" ]; then
                # For single file, we need to handle destination differently
                local basename_file
                basename_file=$(basename "$filepath" .bz2)
                bunzip2 -c "$filepath" > "$dest_dir/$basename_file"
            else
                bunzip2 "$filepath"
            fi
            ;;
        *.rar)      
            if command -v unrar >/dev/null 2>&1; then
                if [ -n "$dest_dir" ]; then
                    unrar x "$filepath" "$dest_dir/"
                else
                    unrar x "$filepath"
                fi
            else
                if [ -n "$dest_dir" ]; then
                    rar x "$filepath" "$dest_dir/"
                else
                    rar x "$filepath"
                fi
            fi
            ;;
        *.gz)       
            if [ -n "$dest_dir" ]; then
                local basename_file
                basename_file=$(basename "$filepath" .gz)
                gunzip -c "$filepath" > "$dest_dir/$basename_file"
            else
                gunzip "$filepath"
            fi
            ;;
        *.tar)      
            if [ -n "$dest_dir" ]; then
                tar xf "$filepath" -C "$dest_dir"
            else
                tar xf "$filepath"
            fi
            ;;
        *.tbz2)     
            if [ -n "$dest_dir" ]; then
                tar xjf "$filepath" -C "$dest_dir"
            else
                tar xjf "$filepath"
            fi
            ;;
        *.tgz)      
            if [ -n "$dest_dir" ]; then
                tar xzf "$filepath" -C "$dest_dir"
            else
                tar xzf "$filepath"
            fi
            ;;
        *.xz)       
            if [ -n "$dest_dir" ]; then
                local basename_file
                basename_file=$(basename "$filepath" .xz)
                xz -dc "$filepath" > "$dest_dir/$basename_file"
            else
                xz -d "$filepath"
            fi
            ;;
        *.zip)      
            if [ -n "$dest_dir" ]; then
                unzip "$filepath" -d "$dest_dir"
            else
                unzip "$filepath"
            fi
            ;;
        *.Z)        
            if [ -n "$dest_dir" ]; then
                local basename_file
                basename_file=$(basename "$filepath" .Z)
                uncompress -c "$filepath" > "$dest_dir/$basename_file"
            else
                uncompress "$filepath"
            fi
            ;;
        *.7z)
            if [ -n "$dest_dir" ]; then
                7z x "$filepath" -o"$dest_dir"
            else
                7z x "$filepath"
            fi
            ;;
    esac
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <compressed_file> [destination_directory]"
    echo ""
    echo "Examples:"
    echo "  $0 archive.tar.gz                    # Extract to current directory"
    echo "  $0 archive.tar.gz ./my_folder        # Extract to ./my_folder"
    echo "  $0 archive.zip /tmp/extracted        # Extract to /tmp/extracted"
    exit 1
fi

ARCHIVE_FILE="$1"
DEST_DIR="$2"

# Check if file command exists
check_command "file"

# Validate archive file
if [ ! -f "$ARCHIVE_FILE" ]; then
    echo "ERROR: '$ARCHIVE_FILE' is not a valid file or does not exist"
    exit 1
fi

# Create and validate destination directory if specified
if [ -n "$DEST_DIR" ]; then
    if [ -e "$DEST_DIR" ] && [ ! -d "$DEST_DIR" ]; then
        echo "ERROR: '$DEST_DIR' exists but is not a directory"
        exit 1
    fi
    
    if [ ! -d "$DEST_DIR" ]; then
        echo "Creating destination directory: $DEST_DIR"
        mkdir -p "$DEST_DIR"
        if [ $? -ne 0 ]; then
            echo "ERROR: Unable to create destination directory '$DEST_DIR'"
            exit 1
        fi
    fi
    
    # Check if destination directory is writable
    if [ ! -w "$DEST_DIR" ]; then
        echo "ERROR: Destination directory '$DEST_DIR' is not writable"
        exit 1
    fi
    
    echo "Destination: $DEST_DIR"
fi

# Determine archive type and verify
case "$ARCHIVE_FILE" in
    *.tar.bz2)  
        verify_file_type "$ARCHIVE_FILE" "bzip2 compressed.*tar archive\|tar archive.*bzip2 compressed"
        check_command "tar"
        ;;
    *.tar.gz)   
        verify_file_type "$ARCHIVE_FILE" "gzip compressed.*tar archive\|tar archive.*gzip compressed"
        check_command "tar"
        ;;
    *.tar.xz)   
        verify_file_type "$ARCHIVE_FILE" "XZ compressed.*tar archive\|tar archive.*XZ compressed"
        check_command "tar"
        ;;
    *.bz2)      
        verify_file_type "$ARCHIVE_FILE" "bzip2 compressed"
        check_command "bunzip2"
        ;;
    *.rar)      
        verify_file_type "$ARCHIVE_FILE" "RAR archive"
        if ! command -v unrar >/dev/null 2>&1 && ! command -v rar >/dev/null 2>&1; then
            echo "ERROR: Neither 'unrar' nor 'rar' is installed"
            echo "Please install 'unrar' to extract RAR files"
            exit 1
        fi
        ;;
    *.gz)       
        verify_file_type "$ARCHIVE_FILE" "gzip compressed"
        check_command "gunzip"
        ;;
    *.tar)      
        verify_file_type "$ARCHIVE_FILE" "tar archive\|POSIX tar archive"
        check_command "tar"
        ;;
    *.tbz2)     
        verify_file_type "$ARCHIVE_FILE" "bzip2 compressed.*tar archive\|tar archive.*bzip2 compressed"
        check_command "tar"
        ;;
    *.tgz)      
        verify_file_type "$ARCHIVE_FILE" "gzip compressed.*tar archive\|tar archive.*gzip compressed"
        check_command "tar"
        ;;
    *.xz)       
        verify_file_type "$ARCHIVE_FILE" "XZ compressed"
        check_command "xz"
        ;;
    *.zip)      
        verify_file_type "$ARCHIVE_FILE" "Zip archive\|ZIP archive"
        check_command "unzip"
        ;;
    *.Z)        
        verify_file_type "$ARCHIVE_FILE" "compress.d data\|LZW compressed"
        check_command "uncompress"
        ;;
    *.7z)
        verify_file_type "$ARCHIVE_FILE" "7-zip archive"
        check_command "7z"
        ;;
    *)          
        echo "ERROR: File type not supported or not recognized"
        echo "Supported formats: tar.bz2, tar.gz, tar.xz, bz2, rar, gz, tar, tbz2, tgz, xz, zip, Z, 7z"
        exit 1 
        ;;
esac

# Preview archive contents and perform sanity checks
preview_and_check_archive "$ARCHIVE_FILE" "$DEST_DIR"

# Perform extraction
echo "Extracting '$ARCHIVE_FILE'..."
extract_archive "$ARCHIVE_FILE" "$DEST_DIR"

# Capture exit status
extraction_status=$?

if [ $extraction_status != 0 ]; then
    echo "ERROR: Extraction failed"
    exit 1
fi

echo "Extraction completed successfully"
if [ -n "$DEST_DIR" ]; then
    echo "Contents extracted to: $DEST_DIR"
fi

# Only ask about removal if file still exists (some tools auto-remove)
if [ -f "$ARCHIVE_FILE" ]; then
    echo -n "Do you want to remove the original file ($ARCHIVE_FILE) [Y/n]? "
    read -r ans
    case "$ans" in
        [Nn]* )
            echo "Original file ($ARCHIVE_FILE) retained"
            ;;
        * )
            rm "$ARCHIVE_FILE"
            if [ $? -eq 0 ]; then
                echo "Original file '$ARCHIVE_FILE' removed"
            else
                echo "ERROR: Failed to remove '$ARCHIVE_FILE'"
                exit 1
            fi
            ;;
    esac
else
    echo "Original file was automatically removed during extraction"
fi
