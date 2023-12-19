backend_service_string="[Unit]
Description=Backend for dash

[Service]
ExecStart=python3 app.py
WorkingDirectory=$(pwd)/dash
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root

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
User=root

[Install]
WantedBy=multi-user.target"

echo "$backend_service_string" > dashBackEnd.service
echo "$frontend_service_string" > front.service