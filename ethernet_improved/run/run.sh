#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the Python interpreter in the 'venv' directory located in the script's directory
PYTHON_INTERPRETER="$SCRIPT_DIR/venv/bin/python"

# Check if the Python interpreter exists
if [ ! -x "$PYTHON_INTERPRETER" ]; then
    echo "Error: Python interpreter not found at $PYTHON_INTERPRETER"
    exit 1
fi

# Check if a Python script argument is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 <path_to_python_script>"
    exit 1
fi

# Path to the Python script to run (first argument)
PYTHON_SCRIPT="$1"

# Check if the Python script exists
if [ ! -f "$PYTHON_SCRIPT" ]; then
    echo "Error: Python script not found at $PYTHON_SCRIPT"
    exit 1
fi

# Run the Python script with sudo using the specified interpreter
sudo "$PYTHON_INTERPRETER" "$PYTHON_SCRIPT"

