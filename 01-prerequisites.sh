#!/bin/bash

set -e  # Exit script on any error
set -o pipefail  # Ensure errors in pipelines are detected
LOGFILE="/var/log/script_installation.log"

# Log output to a file
exec > >(tee -a "$LOGFILE") 2>&1

# Functions for error handling
error_exit() {
    echo "Error: $1" >&2
    exit 1
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        error_exit "$1 is not installed correctly!"
    else
        echo "$1 is installed correctly."
    fi
}

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root."
fi

echo "Updating package list..."
sudo apt-get update -y || error_exit "Failed to update package list."

echo "Installing Git..."
sudo apt-get install git-all -y || error_exit "Failed to install Git."

echo "Installing Curl..."
sudo apt-get install curl -y || error_exit "Failed to install Curl."

echo "Installing dependencies for Docker..."
sudo apt-get install ca-certificates curl -y || error_exit "Failed to install dependencies."

echo "Adding Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc || error_exit "Failed to add Docker GPG key."
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null || error_exit "Failed to add Docker repository."

echo "Installing Docker..."
sudo apt-get update -y || error_exit "Failed to update package list."
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y || error_exit "Failed to install Docker."

echo "Enabling Docker to start on boot..."
sudo systemctl enable docker || error_exit "Failed to enable Docker."

echo "Installing NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash || error_exit "Failed to install NVM."

echo "Loading NVM..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"

echo "Installing Node.js via NVM..."
nvm install 22 || error_exit "Failed to install Node.js."

echo "Installing MySQL Server..."
sudo apt-get install mysql-server -y || error_exit "Failed to install MySQL Server."

echo "Enabling MySQL to start on boot..."
sudo systemctl enable mysql || error_exit "Failed to enable MySQL."

## Verification
echo "Verifying installations..."

# Git
check_command git

# Curl
check_command curl

# Node.js
node_version=$(node -v)
if [[ $node_version == v22* ]]; then
    echo "Node.js version $node_version is installed correctly."
else
    error_exit "Node.js is not installed correctly!"
fi

# NPM
check_command npm

# Docker
sudo service docker start || error_exit "Failed to start Docker service."
sudo docker run hello-world || error_exit "Docker is not working correctly."

# MySQL
sudo service mysql status || error_exit "MySQL service is not running."
sudo ss -tap | grep mysql || error_exit "MySQL service is not listening."

echo "All installations and services are working correctly!"
