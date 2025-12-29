#!/bin/bash

# Fidelio VPS Setup Script
# Este script instala Docker, Docker Compose e prepara o ambiente

set -e

echo "🚀 Fidelio VPS Setup - Instalação Completa"
echo "=========================================="
echo ""

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Por favor, execute como root (use sudo)${NC}"
    exit 1
fi

echo -e "${BLUE}1. Atualizando sistema...${NC}"
apt update && apt upgrade -y

echo -e "${GREEN}✓${NC} Sistema atualizado"
echo ""

echo -e "${BLUE}2. Instalando dependências básicas...${NC}"
apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    wget \
    nano

echo -e "${GREEN}✓${NC} Dependências instaladas"
echo ""

echo -e "${BLUE}3. Instalando Docker...${NC}"

# Remover versões antigas
apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Adicionar repositório Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Iniciar Docker
systemctl start docker
systemctl enable docker

echo -e "${GREEN}✓${NC} Docker instalado e iniciado"
echo ""

echo -e "${BLUE}4. Instalando Docker Compose...${NC}"

# Instalar docker-compose standalone
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo -e "${GREEN}✓${NC} Docker Compose instalado"
echo ""

echo -e "${BLUE}5. Configurando firewall (UFW)...${NC}"

# Instalar e configurar UFW
apt install -y ufw

# Configurar regras
ufw --force enable
ufw allow 22/tcp   # SSH
ufw allow 80/tcp   # HTTP
ufw allow 443/tcp  # HTTPS

echo -e "${GREEN}✓${NC} Firewall configurado"
echo ""

echo -e "${BLUE}6. Criando diretório da aplicação...${NC}"

# Criar diretório
mkdir -p /opt/fidelio
cd /opt/fidelio

echo -e "${GREEN}✓${NC} Diretório criado: /opt/fidelio"
echo ""

# Verificar versões
echo -e "${BLUE}Versões instaladas:${NC}"
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker-compose --version)"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Setup completo!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. Envie os arquivos do projeto para /opt/fidelio"
echo "2. Configure o arquivo .env"
echo "3. Execute: cd /opt/fidelio && chmod +x deploy.sh && ./deploy.sh"
echo ""
echo -e "${BLUE}Comando para enviar arquivos (do seu PC):${NC}"
echo "scp -r d:\\DHSA\\Ticket\\* root@72.61.41.92:/opt/fidelio/"
echo ""
