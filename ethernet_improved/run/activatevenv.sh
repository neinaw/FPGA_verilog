#!/bin/bash

# Path to the virtual environment
VENV_PATH="./venv"  # Change this to the path of your virtual environment

# Check if the virtual environment exists
if [ -d "$VENV_PATH" ]; then
    echo "Activating virtual environment at: $VENV_PATH"
    source "$VENV_PATH/bin/activate"
    if [ $? -eq 0 ]; then
        echo "Virtual environment activated."
    else
        echo "Error: Failed to activate the virtual environment."
    fi
else
    echo "Error: Virtual environment not found at $VENV_PATH"
    exit 1
fi

