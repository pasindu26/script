#!/bin/bash

set -e  # Exit script on any error
set -o pipefail  # Ensure errors in pipelines are detected

# Load environment variables from the base .env file
if [[ -f .env ]]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Error: .env file not found in the current directory!"
    exit 1
fi

# Ensure required environment variables are set
if [[ -z "$SECRET_KEY" || -z "$MYSQL_DB" || -z "$MYSQL_USER" || -z "$MYSQL_PASSWORD" || -z "$APP_SERVER_IP" ]]; then
    echo "Error: Missing required environment variables in .env file!"
    exit 1
fi

# Define repository details
REPO_URL="https://github.com/pasindu26/research.git"
REPO_DIR="research"

# Clone the repository
echo "Cloning the repository..."
if [[ -d $REPO_DIR ]]; then
    echo "Repository directory already exists. Pulling latest changes..."
    cd $REPO_DIR && git pull || {
        echo "Error: Failed to pull latest changes!"
        exit 1
    }
else
    git clone "$REPO_URL" || {
        echo "Error: Failed to clone the repository!"
        exit 1
    }
    cd $REPO_DIR
fi

# Replace values in backend .env file
BACKEND_ENV_FILE="backend/.env"
echo "Configuring backend .env file..."
if [[ -f $BACKEND_ENV_FILE ]]; then
    cat > $BACKEND_ENV_FILE <<EOF
SECRET_KEY=$SECRET_KEY
MYSQL_HOST=$APP_SERVER_IP
MYSQL_USER=$MYSQL_USER
MYSQL_PASSWORD=$MYSQL_PASSWORD
MYSQL_DB=$MYSQL_DB
FLASK_ENV=development

FRONTEND_URL=http://$APP_SERVER_IP
CORS_ORIGIN=http://$APP_SERVER_IP
EOF
    echo "Backend .env file configured successfully."
else
    echo "Error: Backend .env file not found at $BACKEND_ENV_FILE!"
    exit 1
fi

# Replace values in frontend .env file
FRONTEND_ENV_FILE="frontend/.env"
echo "Configuring frontend .env file..."
if [[ -f $FRONTEND_ENV_FILE ]]; then
    cat > $FRONTEND_ENV_FILE <<EOF
REACT_APP_BACKEND_URL=http://$APP_SERVER_IP:5000
EOF
    echo "Frontend .env file configured successfully."
else
    echo "Error: Frontend .env file not found at $FRONTEND_ENV_FILE!"
    exit 1
fi

# Verification
echo "Verifying .env files..."
if grep -q "$SECRET_KEY" "$BACKEND_ENV_FILE" && grep -q "$MYSQL_DB" "$BACKEND_ENV_FILE" && \
   grep -q "$APP_SERVER_IP" "$FRONTEND_ENV_FILE"; then
    echo "All environment variable replacements were successful!"
else
    echo "Error: Verification failed for .env file replacements!"
    exit 1
fi

echo "Repository setup and .env configuration completed successfully!"
