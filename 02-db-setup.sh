#!/bin/bash

set -e  # Exit script on error
set -o pipefail  # Ensure errors in pipelines are detected

# Load environment variables
if [[ -f .env ]]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Error: .env file not found!"
    exit 1
fi

# Ensure required environment variables are set
if [[ -z "$MYSQL_DB" || -z "$MYSQL_USER" || -z "$MYSQL_PASSWORD" ]]; then
    echo "Error: Missing required environment variables in .env file!"
    exit 1
fi

echo "Updating MySQL configuration to allow remote connections..."

# Update MySQL bind address
MYSQL_CONFIG_FILE="/etc/mysql/mysql.conf.d/mysqld.cnf"
if [[ -f $MYSQL_CONFIG_FILE ]]; then
    sudo sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' $MYSQL_CONFIG_FILE || {
        echo "Failed to update MySQL configuration."
        exit 1
    }
else
    echo "MySQL configuration file not found at $MYSQL_CONFIG_FILE"
    exit 1
fi

# Restart MySQL to apply changes
echo "Restarting MySQL service..."
sudo systemctl restart mysql || {
    echo "Failed to restart MySQL service."
    exit 1
}

# Open port 3306 in the firewall
echo "Configuring firewall to allow MySQL traffic on port 3306..."
sudo ufw allow 3306/tcp || {
    echo "Failed to allow port 3306 in the firewall."
    exit 1
}
sudo ufw reload || {
    echo "Failed to reload the firewall."
    exit 1
}

# Log in to MySQL and set up database and tables
echo "Setting up database and tables..."
mysql -u root -p <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DB;

USE $MYSQL_DB;

CREATE TABLE IF NOT EXISTS sensor_data (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ph_value FLOAT NOT NULL,
    temperature FLOAT NOT NULL,
    turbidity FLOAT NOT NULL,
    location VARCHAR(255) NOT NULL,
    time VARCHAR(50) NOT NULL,
    date VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    user_type ENUM('customer', 'admin') NOT NULL DEFAULT 'customer'
);

CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

if [[ $? -eq 0 ]]; then
    echo "Database setup completed successfully!"
else
    echo "Error: Database setup failed!"
    exit 1
fi

# Verify MySQL is running and port is open
echo "Verifying MySQL service and firewall configuration..."
sudo systemctl status mysql || {
    echo "MySQL service is not running!"
    exit 1
}
sudo ss -tap | grep -q ":3306" || {
    echo "MySQL port 3306 is not open!"
    exit 1
}

echo "MySQL setup is complete, and all configurations are verified!"