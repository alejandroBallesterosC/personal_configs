#!/bin/bash

# Exit on errors
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Navigate to the project root (assuming script is in .vscode/scripts)
cd "$SCRIPT_DIR/../.."

# Hardcoded relative input and output directories
INPUT_DIR="./latex_files"
OUTPUT_DIR="./pdfs"

# Ensure input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "Error: Input directory '$INPUT_DIR' does not exist."
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Temporary directory for compilation
TEMP_DIR="$INPUT_DIR/latex_temp"
mkdir -p "$TEMP_DIR"

# Tell LaTeX where to find .cls and .sty files
export TEXINPUTS="$INPUT_DIR:"

# Process each .tex file in the input directory
for tex_file in "$INPUT_DIR"/*.tex; do
    # Skip if no .tex files are found
    [ -f "$tex_file" ] || { echo "No .tex files found in $INPUT_DIR"; exit 1; }

    filename=$(basename -- "$tex_file")
    base_name="${filename%.tex}"

    echo "Compiling: $filename..."

    # Run pdflatex to compile the .tex file
    pdflatex -output-directory "$TEMP_DIR" -interaction=nonstopmode "$tex_file" > "compile_log.log" 2>&1

    # Move the generated PDF to the output directory
    if [ -f "$TEMP_DIR/$base_name.pdf" ]; then
        mv "$TEMP_DIR/$base_name.pdf" "$OUTPUT_DIR/"
        echo "✔ Successfully compiled: $base_name.pdf -> $OUTPUT_DIR/"
    else
        echo "❌ Error: Failed to generate PDF for $filename"
    fi
done

# Clean up auxiliary files
rm -rf "$TEMP_DIR"

echo "✅ Compilation complete!"
