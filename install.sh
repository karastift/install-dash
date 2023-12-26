#!/bin/bash

log() {
    GREEN=$(tput setaf 2)
    NO_COLOR=$(tput sgr0)
    echo -e "${GREEN}[dash-install] $1${NO_COLOR}"
}

log_warning() {
    YELLOW=$(tput setaf 3)
    NO_COLOR=$(tput sgr0)
    echo -e "${YELLOW}[dash-install] $1${NO_COLOR}"
}

log_error() {
    RED=$(tput setaf 1)
    NO_COLOR=$(tput sgr0)
    echo -e "${RED}[dash-install] $1${NO_COLOR}"
}

# Ensure to run a with root privileges
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    log_error "This script needs to be run as root! Exiting..."
    exit 1
fi

# Ask for options
read -p "$(tput setaf 4)Enter screen width [1152]: $(tput setaf 0)" screen_width
screen_width=${screen_width:-1152}

read -p "$(tput setaf 4)Enter screen height [864]: $(tput setaf 0)" screen_height
screen_height=${screen_height:-864}

# Install necessary dependencies
log "Installing necessary dependencies: python3-pip python3-venv chromium-browser xorg"
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv chromium-browser xorg

# Uninstall old Docker versions
log "Uninstalling old Docker versions"

packages_to_remove=("docker.io" "docker-doc" "docker-compose" "podman-docker" "containerd" "runc")

for pkg in "${packages_to_remove[@]}"; do
    if dpkg -l | grep -q "^ii  $pkg "; then
        log_warning "$pkg is installed. Removing it $pkg"
        sudo apt-get remove "$pkg"
    else
        log "$pkg is not installed (That's good)"
    fi
done

# Add Docker's official GPG key:
log "Adding Docker's official GPG key"
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to apt sources:
log "Add the docker repository to apt sources"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages
log "Installing docker packages: docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Set up the Vue frontend (in Docker)
log "Building frontend docker container"
cd ./frontend
sudo docker compose build

# Set up and run the Flask server
log "Creating virtual environment and installing requirements for backend"
cd ../backend
python3 -m venv venv
./venv/bin/pip install -r requirements.txt

cd ..

# Create service for backend
log "Creating .service file for backend"
echo "[Unit]
Description=dash backend

[Service]
Type=simple
ExecStart=$(pwd)/backend/venv/bin/python3 $(pwd)/backend/app.py

[Install]
WantedBy=default.target" > ./dash-backend.service

# Create service for frontend
log "Creating .service file for frontend"
echo "[Unit]
Description=dash frontend

[Service]
Type=simple
ExecStart=/usr/bin/docker compose up
WorkingDirectory=$(pwd)/frontend

[Install]
WantedBy=default.target" > ./dash-frontend.service

log "Copying service files into /etc/systemd/system/"
sudo cp ./dash-backend.service /etc/systemd/system/dash-backend.service
sudo cp ./dash-frontend.service /etc/systemd/system/dash-frontend.service

log "Removing service files in this directory"
rm ./*.service

# Reload systemctl and enable services (that they are started on reboot)
log "Reloading systemctl daemon and enabling services"
sudo systemctl daemon-reload
sudo systemctl enable dash-backend.service
sudo systemctl enable dash-frontend.service

# Start backend and frontend
log "Starting frontend, backend service"
sudo systemctl start dash-backend.service
sudo systemctl start dash-frontend.service

# Configure pi to automatically log in as default user on boot
log "Configuring boot behaviour: automatically log in on boot"
sudo raspi-config nonint do_boot_behaviour B2

# Create service for starting browser that displays frontend
log "Creating .service file for starting the x server and displaying chromium"
echo "[Unit]
Description=dash browser starter

[Service]
Type=simple
ExecStart=/usr/bin/xinit /usr/bin/chromium-browser --window-size=$screen_width,$screen_height --no-sandbox --kiosk http://localhost:8080
WorkingDirectory=$(pwd)

[Install]
WantedBy=default.target" > ./dash-browser.service

log "Copying dash-browser.service into /etc/systemd/system/"
sudo cp ./dash-browser.service /etc/systemd/system/dash-browser.service

log "Removing service files in this directory"
rm ./*.service

# Reload systemctl and enable service (that they are started on reboot)
log "Reloading systemctl daemon and enabling dash-browser.service"
sudo systemctl daemon-reload
sudo systemctl enable dash-browser.service

cd ..

log_warning "
!!!
Now installing rpi-audio-receiver, normally just bluetooth module is needed (dont install hifiberry if you are not using it!)
!!!
"

# install rpi-audio-receiver
log "Installing rpi-audio-receiver"
wget -q https://github.com/nicokaiser/rpi-audio-receiver/archive/main.zip
unzip main.zip
rm main.zip

cd rpi-audio-receiver-main
sudo ./install.sh

log_warning "
!!!
DONT FORGET TO CHANGE THE AUDIO DEVICE TO DIGIAMP IN raspi-config and then REBOOT to activate rpi-audio-receiver
!!!
"