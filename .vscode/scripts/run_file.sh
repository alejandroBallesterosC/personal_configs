#!/bin/bash

# Get the filename from VSCode task
FILE="$1"

# Get the file extension
EXT="${FILE##*.}"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get project root (assuming script is in .vscode/scripts)
PROJECT_ROOT="$SCRIPT_DIR/../.."

# # Define build directory inside c++
BUILD_DIR="$PROJECT_ROOT/c++/build"
# BUILD_DIR="${WORKSPACE_FOLDER}/c++/build"

# # Convert absolute path to a workspace-relative path
RELATIVE_PATH="${FILE#$PROJECT_ROOT/}"
# RELATIVE_PATH="${FILE#$WORKSPACE_FOLDER/}"

if [ "$EXT" == "cpp" ]; then
    # Ensure build directory exists
    mkdir -p "$BUILD_DIR"
    
    # Extract filename without extension
    BASENAME=$(basename "$FILE" .cpp)

    # Compile and run
    /usr/bin/clang++ -std=c++23 -O2 -Wall -Wextra -o "$BUILD_DIR/$BASENAME" "$FILE" && "$BUILD_DIR/$BASENAME"

elif [ "$EXT" == "py" ]; then

    # Run Python file using UV
    # uv run "$RELATIVE_PATH"

    # Run Python file using UV in module mode
    # Replace slashes with dots
    RELATIVE_PATH="${RELATIVE_PATH//\//.}"
    RELATIVE_PATH="${RELATIVE_PATH%.py}"
    uv run -m "$RELATIVE_PATH"

else
    echo "Unsupported file type: $EXT"
    exit 1
fi