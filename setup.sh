#!/bin/bash

# Exit script on any error
set -e

# Get the directory where the script is located
SCRIPT_DIR=$(dirname "$0")

# Step 1: Create OpenSchool-Project directory in the same location as the script
echo "Creating project directory in $SCRIPT_DIR/OpenSchools-Project..."
mkdir -p "$SCRIPT_DIR/OpenSchools-Project"
cd "$SCRIPT_DIR/OpenSchools-Project"

# Step 2: Clone the repository into moodle directory
echo "Cloning OpenSchools repository..."
# git clone https://github.com/VincentSD/Openschool.git moodle

# Step 3: Create moodledata directory and set permissions
echo "Creating moodledata directory..."
mkdir moodledata
chmod -R 0777 moodledata

# Step 4: Configure Moodle config.php
echo "Configuring Moodle..."

# Create a backup of the original config-dist.php before modifying it
cp moodle/config-dist.php moodle/config.php

# Set the database details and other required configurations
sed -i "s|\$CFG->wwwroot   = 'http://localhost';|\$CFG->wwwroot   = 'http://localhost';|" moodle/config.php
sed -i "s|\$CFG->dataroot  = '';/|\$CFG->dataroot  = __DIR__ . '/moodledata';|" moodle/config.php
sed -i "s|\$CFG->dbhost    = 'localhost';|\$CFG->dbhost    = 'localhost';|" moodle/config.php
sed -i "s|\$CFG->dbname    = 'moodle';|\$CFG->dbname    = 'moodle';|" moodle/config.php
sed -i "s|\$CFG->dbuser    = 'moodle';|\$CFG->dbuser    = 'moodle';|" moodle/config.php
sed -i "s|\$CFG->dbpass    = 'moodle';|\$CFG->dbpass    = 'moodle';|" moodle/config.php

# Step 5: Install Moodle dependencies using Composer
echo "Installing Moodle dependencies..."
cd moodle
composer install --no-dev

# Step 6: MySQL Database Setup (Assumes MySQL is running locally)
echo "Creating Moodle database (if not already created)..."
mysql -u root -e "CREATE DATABASE IF NOT EXISTS moodle;"

# Step 7: Create .lando.yml file

# Check if the directory is correct and if we can create the file
if [ ! -d "$SCRIPT_DIR/OpenSchools-Project" ]; then
  echo "Error: Project directory not found. Exiting."
  exit 1
fi

echo "Creating .lando.yml file..."
cat <<EOL > ".lando.yml"
name: openschool
recipe: lamp
config:
  webroot: ./moodle
  php: '8.2'
  database: mysql

services:
  appserver:
    type: php:8.2
    overrides:
      environment:
        MOODLE_URL: 'http://openschool'
    volumes:
      - ./moodle:/var/www/html
  database:
    type: mysql:8.0
    portforward: true
    creds:
      user: moodle
      password: moodle
      database: moodle
EOL

# Step 8: Install Moodle
echo "Moodle installation process. Open your browser and navigate to:"
echo "http://localhost"
echo "Follow the installation wizard to complete the setup."

# Finished
echo "Setup complete! You can now access Moodle at http://localhost."
