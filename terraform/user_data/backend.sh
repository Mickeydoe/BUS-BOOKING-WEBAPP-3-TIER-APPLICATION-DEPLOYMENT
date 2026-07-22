#!/bin/bash
set -euxo pipefail

#--------------------------------------------------
# Variables from Terraform
#--------------------------------------------------

REPOSITORY_URL="${repository_url}"

DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_username}"
DB_PASSWORD="${db_password}"
DB_PORT="5432"

APP_DIR="/home/ec2-user/app"
VENV_DIR="/home/ec2-user/venv"

#--------------------------------------------------
# Update instance
#--------------------------------------------------

dnf update -y

dnf install -y \
    git \
    python3 \
    python3-pip \
    python3-devel \
    gcc

#--------------------------------------------------
# Clone repository
#--------------------------------------------------

cd /home/ec2-user
rm -rf "$${APP_DIR}"
git clone --branch refactor --single-branch "$${REPOSITORY_URL}" "$${APP_DIR}"
chown -R ec2-user:ec2-user "$${APP_DIR}"


#--------------------------------------------------
# Python virtual environment
#--------------------------------------------------

python3 -m venv "$${VENV_DIR}"

source "$${VENV_DIR}/bin/activate"

pip install --upgrade pip

pip install -r "$${APP_DIR}/backend/requirements.txt"

#--------------------------------------------------
# Environment variables
#--------------------------------------------------

cat > /etc/passbooking.env <<EOF
DB_HOST=$${DB_HOST}
DB_NAME=$${DB_NAME}
DB_USER=$${DB_USER}
DB_PASSWORD=$${DB_PASSWORD}
DB_PORT=$${DB_PORT}
FLASK_SECRET_KEY=$$(openssl rand -hex 32)
EOF

chmod 600 /etc/passbooking.env

#--------------------------------------------------
# Gunicorn systemd service
#--------------------------------------------------

cat > /etc/systemd/system/passbooking.service <<EOF
[Unit]
Description=Simple Pass Booking Backend
After=network.target

[Service]
User=ec2-user
Group=ec2-user

WorkingDirectory=$${APP_DIR}/backend

EnvironmentFile=/etc/passbooking.env

ExecStart=$${VENV_DIR}/bin/gunicorn \
    --workers 2 \
    --bind 0.0.0.0:5000 \
    app:app

Restart=always

[Install]
WantedBy=multi-user.target
EOF

#--------------------------------------------------
# Start backend
#--------------------------------------------------

systemctl daemon-reload
systemctl enable passbooking
systemctl start passbooking