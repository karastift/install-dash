#!/bin/bash

# Install necessary dependencies
sudo apt-get update
sudo apt-get install -y python3-pip python3-venv

# Set up and run the Flask server
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo "FLASK_SECRET_KEY: kkkkjfjksdjkljkfslkjqjkjklklkas
DASHBOARD_UPDATE_TIME: 5
DEV: false" > config.yml

python3 app.py &

# Set up and run the Vue frontend (in Docker)
cd ../frontend
docker-compose up -d