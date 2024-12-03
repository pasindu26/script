#!/bin/bash

set -e  # Exit script on any error
set -o pipefail  # Ensure errors in pipelines are detected

# Update system and install Python3 and pip
echo "Updating system and installing Python3 and pip..."
sudo apt update -y || { echo "Error: Failed to update system packages!"; exit 1; }
sudo apt install -y python3 python3-pip || { echo "Error: Failed to install Python3 and pip!"; exit 1; }
echo "Python3 and pip installed successfully."

# Load NVM and Node.js environment
echo "Loading NVM and Node.js environment..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" || { echo "Error: NVM is not installed!"; exit 1; }
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

# Verify Node.js and npm installation
echo "Verifying Node.js and npm installation..."
node_version=$(node -v 2>/dev/null || true)
npm_version=$(npm -v 2>/dev/null || true)

if [[ -z "$node_version" ]]; then
    echo "Error: Node.js is not installed! Please install it using NVM."
    exit 1
else
    echo "Node.js version: $node_version"
fi

if [[ -z "$npm_version" ]]; then
    echo "Error: npm is not installed! Please ensure Node.js is installed correctly."
    exit 1
else
    echo "npm version: $npm_version"
fi

# Define the frontend directory
FRONTEND_DIR="research/frontend"

# Navigate to the frontend directory
echo "Navigating to the frontend directory..."
if [[ -d $FRONTEND_DIR ]]; then
    cd $FRONTEND_DIR || { echo "Error: Failed to navigate to $FRONTEND_DIR!"; exit 1; }
else
    echo "Error: Frontend directory not found at $FRONTEND_DIR!"
    exit 1
fi

# Install Node modules
echo "Installing Node modules..."
npm install || { echo "Error: Failed to install Node modules!"; exit 1; }

# Build the React app
echo "Building the React app..."
npm run build || { echo "Error: Failed to build the React app!"; exit 1; }

# Completion message
echo "Frontend setup completed successfully, and backend dependencies are installed!"
