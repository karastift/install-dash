#!/bin/bash

# Install necessary dependencies
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv

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

exit

# Set up and run the Vue frontend (in Docker)
cd ./frontend
docker-compose up -d

# Set up and run the Flask server
cd ../backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "FLASK_SECRET_KEY: kkkkjfjksdjkljkfslkjqjkjklklkas
DASHBOARD_UPDATE_TIME: 5
DEV: false" > config.yml

python3 app.py