apt install xdg-open

git clone https://github.com/karastift/dash
git clone https://github.com/karastift/dash-web

cd dash
python3 -m venv .venv
source ./.venv/bin/activate
python3 -m pip install -r requirements.txt

cd ../dash-web
npm install

cd ..

backend_service_string="[Unit]
Description=Backend for dash

[Service]
ExecStart=python3 app.py
WorkingDirectory=$(pwd)/dash
StandardOutput=inherit
StandardError=inherit
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target"

frontend_service_string="[Unit]
Description=Frontend for dash

[Service]
ExecStart=npm run dev
WorkingDirectory=$(pwd)/dash-web
StandardOutput=inherit
StandardError=inherit
Restart=always
User=$(whoami)

[Install]
WantedBy=multi-user.target"

echo "$backend_service_string" > dashBackEnd.service
echo "$frontend_service_string" > dashFrontEnd.service

sudo cp ./dashBackEnd.service /lib/systemd/system/
sudo cp ./dashFrontEnd.service /lib/systemd/system/

systemctl start dashBackEnd.service
systemctl start dashFrontEnd.service

systemctl enable dashBackEnd.service
systemctl enable dashFrontEnd.service

xdg-open "http://localhost:5173/"