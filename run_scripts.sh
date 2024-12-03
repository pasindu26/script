#!/bin/bash

set -e  # Exit script on any error
set -o pipefail  # Ensure errors in pipelines are detected

# Array of script filenames in the order to be executed
scripts=(
    "01-prerequisites.sh"
    "02-db-setup.sh"
    "03-repo-setup.sh"
    "04-frontend_backend_setup.sh"
    "05-docker-setup.sh"
)

# Execute each script
for script in "${scripts[@]}"; do
    echo "Executing $script..."
    if [[ -x "$script" ]]; then
        # Provide "enter" as user input if needed
        bash "$script" <<< "" || { echo "Error executing $script!"; exit 1; }
    else
        echo "Error: $script is not executable. Make sure it has the proper permissions."
        exit 1
    fi
    echo "$script executed successfully."
done

echo "All scripts executed successfully!"
