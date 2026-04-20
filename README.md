# ⚡ SaaS VPN + VPS Manager — Deploy Automático (Docker + Domínio)

Deploy completo da plataforma usando containers, domínio próprio e HTTPS automático.

---

## 🧠 Arquitetura de Deploy

```id="q2n6k0"
Internet
   ↓
Nginx (HTTPS)
   ↓
Frontend (React build)
   ↓
Backend API (FastAPI)
   ↓
Database
```

---

## 📦 Tecnologias

* Docker
* Docker Compose
* Nginx
* Let's Encrypt
* FastAPI
* React

---

## 🌐 Pré-requisitos

* VPS com Ubuntu 20+
* Domínio apontando para IP do servidor
* Portas abertas:

  * 80 (HTTP)
  * 443 (HTTPS)

---

## 🚀 Instalação rápida

### 1. Instalar Docker

```bash id="g7j4yt"
apt update
apt install -y docker.io docker-compose
systemctl enable docker
```

---

### 2. Estrutura do projeto

```bash id="u3v1ra"
saas-vpn/
├── docker-compose.yml
├── nginx/
│   └── default.conf
├── backend/
├── frontend/
```

---

## 🐳 docker-compose.yml

```yaml id="o9dbv1"
version: "3.9"

services:
  backend:
    build: ./backend
    container_name: backend
    restart: always
    expose:
      - "8000"

  frontend:
    build: ./frontend
    container_name: frontend
    restart: always
    expose:
      - "3000"

  nginx:
    image: nginx:latest
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf
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
```

---

## 🌐 Nginx config

📄 `nginx/default.conf`

```nginx id="g1x91u"
server {
    listen 80;
    server_name seu-dominio.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name seu-dominio.com;

    ssl_certificate /etc/letsencrypt/live/seu-dominio.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/seu-dominio.com/privkey.pem;

    location /api/ {
        proxy_pass http://backend:8000/;
    }

    location / {
        proxy_pass http://frontend:3000;
    }
}
```

---

## 🔐 Gerar certificado SSL

Execute:

```bash id="n1sqwp"
docker-compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  -d seu-dominio.com \
  --email seu@email.com \
  --agree-tos \
  --no-eff-email
```

---

## ▶️ Subir o sistema

```bash id="c7m6j1"
docker-compose up -d --build
```

---

## 🔄 Renovação automática SSL

Adicione ao cron:

```bash id="r2d5he"
0 3 * * * docker-compose run --rm certbot renew && docker-compose restart nginx
```

---

## 📡 Acesso

* Frontend:

```id="y0sjpx"
https://seu-dominio.com
```

* API:

```id="c6k3ot"
https://seu-dominio.com/api
```

---

## 🔐 Segurança recomendada

* usar firewall (UFW)
* desativar login root via SSH
* usar chave SSH
* limitar requisições no Nginx

---

## 🚀 Melhorias futuras

* CDN (ex: Cloudflare)
* load balancer
* múltiplos servidores VPN
* auto scaling

---

## ⚠️ Problemas comuns

### Certificado não gera

* domínio não apontado corretamente

### API não responde

* verificar rota `/api/` no Nginx

### Frontend não carrega

* verificar build React

---

## 📄 Licença

MIT
