#!/bin/bash

set -e  # Exit script on error
set -o pipefail  # Ensure errors in pipelines are detected

# Load environment variables from .env file
if [[ -f .env ]]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Error: .env file not found in the current directory!"
    exit 1
fi

# Ensure required environment variables are set
if [[ -z "$MYSQL_DB" || -z "$MYSQL_USER" || -z "$MYSQL_PASSWORD" || -z "$SECRET_KEY" || -z "$APP_SERVER_IP" || -z "$DOCKER_USERNAME" ]]; then
    echo "Error: Missing required environment variables in .env file!"
    exit 1
fi

# Build Docker image for frontend
echo "Building Docker image for frontend..."
FRONTEND_DIR="research/frontend"
if [[ -d $FRONTEND_DIR ]]; then
    cd $FRONTEND_DIR || { echo "Error: Failed to navigate to $FRONTEND_DIR!"; exit 1; }
    docker build -t "$DOCKER_USERNAME/frontend-app:01" . || { echo "Error: Failed to build frontend Docker image!"; exit 1; }
else
    echo "Error: Frontend directory not found at $FRONTEND_DIR!"
    exit 1
fi

# Build Docker image for backend
echo "Building Docker image for backend..."
BACKEND_DIR="../backend"
if [[ -d $BACKEND_DIR ]]; then
    cd $BACKEND_DIR || { echo "Error: Failed to navigate to $BACKEND_DIR!"; exit 1; }
    docker build -t "$DOCKER_USERNAME/backend-app:01" . || { echo "Error: Failed to build backend Docker image!"; exit 1; }
else
    echo "Error: Backend directory not found at $BACKEND_DIR!"
    exit 1
fi

# Run backend Docker container
echo "Running backend Docker container..."
docker run -d --restart unless-stopped -p 5000:5000 --name backend-app "$DOCKER_USERNAME/backend-app:01" || { echo "Error: Failed to run backend Docker container!"; exit 1; }

# Run frontend Docker container
echo "Running frontend Docker container..."
docker run -d --restart unless-stopped -p 80:80 --name frontend-app "$DOCKER_USERNAME/frontend-app:01" || { echo "Error: Failed to run frontend Docker container!"; exit 1; }

# Completion message
echo "Docker images built and containers started successfully!"
