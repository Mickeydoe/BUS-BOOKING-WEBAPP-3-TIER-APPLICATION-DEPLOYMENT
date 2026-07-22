#!/bin/bash
set -euxo pipefail

#--------------------------------------------------
# Variables from Terraform
#--------------------------------------------------

REPOSITORY_URL="${repository_url}"
BACKEND_URL="${backend_url}"

APP_DIR="/home/ec2-user/app"

#--------------------------------------------------
# Update instance
#--------------------------------------------------

dnf update -y

dnf install -y \
    nginx \
    git

#--------------------------------------------------
# Clone repository
#--------------------------------------------------

rm -rf "$${APP_DIR}"

git clone --branch refactor --single-branch "$${REPOSITORY_URL}" "$${APP_DIR}"

chown -R ec2-user:ec2-user "$${APP_DIR}"

#--------------------------------------------------
# Copy frontend files
#--------------------------------------------------

rm -rf /usr/share/nginx/html/*

cp -r "$${APP_DIR}/frontend/"* /usr/share/nginx/html/

#--------------------------------------------------
# Configure Nginx
#--------------------------------------------------

cat > /etc/nginx/conf.d/passbooking.conf <<EOF
server {

    listen 80;

    server_name _;

    root /usr/share/nginx/html;
    index index.html;

    location / {

        try_files \$uri \$uri/ /index.html;

    }

    location /api/ {

        proxy_pass http://$${BACKEND_URL};

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

    }

}
EOF

#--------------------------------------------------
# Remove default configuration
#--------------------------------------------------

rm -f /etc/nginx/conf.d/default.conf

#--------------------------------------------------
# Validate configuration
#--------------------------------------------------

nginx -t

#--------------------------------------------------
# Enable nginx
#--------------------------------------------------

systemctl enable nginx
systemctl restart nginx
