#!/bin/bash

clear

echo "====================================="
echo "   VPSPACK SaaS - AUTO INSTALLER"
echo "====================================="

# 🔐 Checar root
if [ "$(id -u)" != "0" ]; then
   echo "Execute como root"
   exit 1
fi

# 🌐 Inputs
read -p "Digite seu domínio (ex: vpn.seudominio.com): " DOMAIN
read -p "Digite seu email (SSL): " EMAIL

# 📦 Atualizar sistema
apt update -y && apt upgrade -y

# 🐳 Instalar Docker
apt install -y docker.io docker-compose curl
systemctl enable docker
systemctl start docker

# 📁 Criar estrutura
mkdir -p /opt/saas-vpn
cd /opt/saas-vpn

# 📄 docker-compose.yml
cat > docker-compose.yml <<EOF
version: "3.9"

services:
  backend:
    image: tiangolo/uvicorn-gunicorn-fastapi:python3.11
    volumes:
      - ./backend:/app
    restart: always

  frontend:
    image: node:18
    working_dir: /app
    volumes:
      - ./frontend:/app
    command: sh -c "npm install && npm run build && npx serve -s build"
    restart: always

  nginx:
    image: nginx:latest
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - backend
      - frontend

  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
EOF

# 📄 nginx config
cat > nginx.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location /api/ {
        proxy_pass http://backend:80/;
    }

    location / {
        proxy_pass http://frontend:3000;
    }
}
EOF

# 📁 Criar backend básico
mkdir backend
cat > backend/main.py <<EOF
from fastapi import FastAPI
app = FastAPI()

@app.get("/")
def root():
    return {"status": "ok"}
EOF

# 📁 Criar frontend simples
mkdir frontend
cat > frontend/package.json <<EOF
{
  "name": "frontend",
  "version": "1.0.0",
  "dependencies": {
    "serve": "^14.2.0"
  },
  "scripts": {
    "build": "echo build",
    "start": "serve -s ."
  }
}
EOF

echo "<h1 style='color:#00ffcc;background:black'>CYBER SaaS ONLINE ⚡</h1>" > frontend/index.html

# 🚀 Subir containers (HTTP primeiro)
docker-compose up -d

sleep 5

# 🔐 Gerar SSL
docker-compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  -d $DOMAIN \
  --email $EMAIL \
  --agree-tos \
  --no-eff-email

# 🔄 Reiniciar nginx com SSL
docker-compose restart nginx

# 🔁 Auto-renew
(crontab -l 2>/dev/null; echo "0 3 * * * cd /opt/saas-vpn && docker-compose run --rm certbot renew && docker-compose restart nginx") | crontab -

clear

echo "====================================="
echo "   🚀 INSTALAÇÃO CONCLUÍDA!"
echo "====================================="
echo "Acesse: https://$DOMAIN"
echo ""
echo "Backend API: https://$DOMAIN/api"
echo "====================================="
