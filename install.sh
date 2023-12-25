#!/bin/bash

if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "This script needs to be run as root. Exiting..."
    exit
fi

# Install necessary dependencies
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv chromium-browser xorg

# Uninstall old docker verions
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Set up the Vue frontend (in Docker)
cd ./frontend
sudo docker compose build

# Set up and run the Flask server
cd ../backend
python3 -m venv venv
./venv/bin/pip install -r requirements.txt

cd ..

# Create service for backend
echo "[Unit]
Description=dash backend

[Service]
Type=simple
ExecStart=$(pwd)/backend/venv/bin/python3 $(pwd)/backend/app.py

[Install]
WantedBy=default.target" > ./dash-backend.service

# Create service for frontend
echo "[Unit]
Description=dash frontend

[Service]
Type=simple
ExecStart=/usr/bin/docker compose up
WorkingDirectory=$(pwd)/frontend

[Install]
WantedBy=default.target" > ./dash-frontend.service

sudo cp ./dash-backend.service /etc/systemd/system/dash-backend.service
sudo cp ./dash-frontend.service /etc/systemd/system/dash-frontend.service

# Reload systemctl and enable services (that they are started on reboot)
sudo systemctl daemon-reload
sudo systemctl enable dash-backend.service
sudo systemctl enable dash-frontend.service

# Start backend and frontend
sudo systemctl start dash-backend.service
sudo systemctl start dash-frontend.service

# Configure pi to automatically log in as default user on boot
sudo raspi-config nonint do_boot_behaviour B4

# configure x server to display chromium in kiosk mode and display frontend
echo "/usr/bin/chromium-browser --kiosk http://localhost:8080 --start-fullscreen --window-size=1024,600" > ~/.xinitrc

# start x server, without rebooting
startx