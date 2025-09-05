#!/usr/bin/env bash
#
# recursive_download - Recursively download content from a website with specified depth
# Usage: ./recursive_download.sh URL ">RECURSIVE=N<"
# Note: N must be between 1 and 5

set -e

# Check if at least URL is provided
if [ $# -lt 1 ]; then
  echo "Usage: $0 URL [RECURSIVE_PARAM]"
  echo "Example: $0 https://www.example.com \">RECURSIVE=5<\""
  exit 1
fi

URL="$1"
RECURSIVE_DEPTH=0

# Validate URL format (must start with http:// or https://)
if [[ ! "$URL" =~ ^https?:// ]]; then
  echo "Error: URL must start with http:// or https://"
  exit 1
fi

# Check for recursive parameter
if [ $# -gt 1 ]; then
  PARAM="$2"
  # Extract recursive depth from parameter
  if [[ "$PARAM" =~ \>RECURSIVE=([1-5])\< ]]; then
    RECURSIVE_DEPTH="${BASH_REMATCH[1]}"
    echo "Recursive depth set to: $RECURSIVE_DEPTH"
  else
    echo "Invalid recursive parameter format. Using default depth of 0."
  fi
fi

# Ensure depth is not greater than 3
if [ "$RECURSIVE_DEPTH" -gt 3 ]; then
  echo "Limiting recursive depth to maximum of 3."
  RECURSIVE_DEPTH=3
fi

# Extract domain from URL
DOMAIN=$(echo "$URL" | sed -E 's|^https?://||' | sed -E 's|^www\.||' | cut -d'/' -f1)

# Create a safe directory name from the URL
DIR_NAME="${DOMAIN}_recursive"

# Create directory if it doesn't exist
mkdir -p "$DIR_NAME"
cd "$DIR_NAME"

echo "Starting recursive download from $URL with depth $RECURSIVE_DEPTH"
echo "Downloaded files will be saved in: $(pwd)"

# If recursive depth is 0, just do a regular download
if [ "$RECURSIVE_DEPTH" -eq 0 ]; then
  echo "Recursive depth is 0, performing single page download"
  cd ..
  ./download.sh "$URL"
  exit 0
fi

# Build the wget command with options that are known to work
echo "Starting recursive download with depth $RECURSIVE_DEPTH..."

# Using a simpler approach with a reject list instead of an accept list
wget \
  -e robots=off \
  --recursive \
  --level="$RECURSIVE_DEPTH" \
  --wait=1 \
  --random-wait \
  --domains="$DOMAIN" \
  --timeout=100 \
  --tries=3 \
  --reject="pdf,png,jpg,jpeg,gif,css,js,ts,svg,woff,woff2,ttf,eot,mp4,webm,mp3,zip,tar,gz" \
  --convert-links \
  --adjust-extension \
  --restrict-file-names=windows \
  "$URL"

# Check if we got some files
FILE_COUNT=$(find . -type f | wc -l)
echo "Downloaded $FILE_COUNT files."

# If we didn't get any files, try once more without some restrictions
if [ "$FILE_COUNT" -lt 2 ]; then
  echo "Very few files downloaded. Trying with fewer restrictions..."
  rm -rf ./*
  
  wget \
    -e robots=off \
    --recursive \
    --level="$RECURSIVE_DEPTH" \
    --wait=1 \
    --domains="$DOMAIN" \
    --timeout=100 \
    --reject="pdf,png,jpg,jpeg,gif" \
    "$URL"
    
  FILE_COUNT=$(find . -type f | wc -l)
  echo "Second attempt downloaded $FILE_COUNT files."
fi

# Post-process downloaded files to remove unchanged content
echo "Checking for unchanged files..."
UNCHANGED_COUNT=0
CHANGED_COUNT=0

# Create a temporary backup directory
BACKUP_DIR="../${DIR_NAME}_backup"
if [ -d "$BACKUP_DIR" ]; then
  echo "Found existing backup directory, comparing files..."
  
  # Compare each file with its backup
  find . -type f | while read -r file; do
    BACKUP_FILE="$BACKUP_DIR/$file"
    if [ -f "$BACKUP_FILE" ]; then
      if cmp -s "$file" "$BACKUP_FILE"; then
        echo "Removing unchanged file: $file"
        rm -f "$file"
        # Remove parent directories if they become empty
        DIR=$(dirname "$file")
        while [ "$DIR" != "." ] && [ -z "$(find "$DIR" -mindepth 1 -type f 2>/dev/null)" ]; do
          rmdir "$DIR" 2>/dev/null || break
          DIR=$(dirname "$DIR")
        done
      fi
    fi
  done
  
  # Count remaining files
  CHANGED_COUNT=$(find . -type f | wc -l)
  echo "Files with changes: $CHANGED_COUNT"
else
  echo "No previous backup found, all files are new"
  CHANGED_COUNT=$(find . -type f | wc -l)
fi

# Create/update backup for next run
rm -rf "$BACKUP_DIR"
cp -r . "$BACKUP_DIR"
echo "Created backup for next comparison"

echo "Recursive download completed. Files saved in: $(pwd)"

# Return to original directory
cd ..