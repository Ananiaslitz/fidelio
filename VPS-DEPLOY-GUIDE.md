# Deploy Fidelio na VPS - Guia Passo a Passo

## 🎯 VPS: 72.61.41.92

## Passo 1: Preparar a VPS

### 1.1 Conectar na VPS
```bash
ssh root@72.61.41.92
```

### 1.2 Criar e executar script de setup
```bash
# Criar arquivo
cat > vps-setup.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Instalando Docker e dependências..."

# Atualizar sistema
apt update && apt upgrade -y

# Instalar dependências
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release git wget nano

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Instalar Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configurar firewall
apt install -y ufw
ufw --force enable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# Criar diretório
mkdir -p /opt/fidelio

echo "✓ Setup completo!"
docker --version
docker-compose --version
EOF

# Dar permissão e executar
chmod +x vps-setup.sh
./vps-setup.sh
```

## Passo 2: Enviar Arquivos (do seu PC Windows)

### 2.1 Abrir PowerShell e executar:
```powershell
# Ir para o diretório do projeto
cd d:\DHSA\Ticket

# Enviar todos os arquivos
scp -r * root@72.61.41.92:/opt/fidelio/
```

**Importante**: Isso vai enviar:
- ✅ docker-compose.production.yml
- ✅ .env (com suas credenciais)
- ✅ deploy.sh
- ✅ setup-ssl.sh
- ✅ nginx/
- ✅ backend/
- ✅ web-portal/
- ✅ migrations/
- ✅ Dockerfile

## Passo 3: Deploy na VPS

### 3.1 Voltar para SSH da VPS
```bash
ssh root@72.61.41.92
cd /opt/fidelio
```

### 3.2 Verificar se arquivos foram enviados
```bash
ls -la
```

Você deve ver:
- docker-compose.production.yml
- .env
- deploy.sh
- nginx/
- backend/
- web-portal/
- etc.

### 3.3 Executar deploy
```bash
chmod +x deploy.sh
./deploy.sh
```

## Passo 4: Verificar se está funcionando

### 4.1 Ver status dos containers
```bash
docker-compose -f docker-compose.production.yml ps
```

### 4.2 Ver logs
```bash
docker-compose -f docker-compose.production.yml logs -f
```

### 4.3 Testar no navegador
Acesse: **http://72.61.41.92**

API: **http://72.61.41.92/api/health**

## Passo 5: Configurar SSL (Opcional - após ter domínio)

Quando você tiver o domínio configurado:

```bash
# 1. Atualizar .env com seu domínio
nano .env
# Alterar: DOMAIN=seudominio.cloud
# Alterar: CERTBOT_EMAIL=seu-email@example.com

# 2. Executar setup SSL
chmod +x setup-ssl.sh
./setup-ssl.sh
```

## 🔧 Comandos Úteis

```bash
# Ver logs em tempo real
docker-compose -f docker-compose.production.yml logs -f

# Ver logs de um serviço específico
docker-compose -f docker-compose.production.yml logs -f api
docker-compose -f docker-compose.production.yml logs -f web-portal
docker-compose -f docker-compose.production.yml logs -f nginx

# Status dos containers
docker-compose -f docker-compose.production.yml ps

# Reiniciar tudo
docker-compose -f docker-compose.production.yml restart

# Parar tudo
docker-compose -f docker-compose.production.yml down

# Rebuild e restart (após mudanças no código)
docker-compose -f docker-compose.production.yml down
docker-compose -f docker-compose.production.yml build --no-cache
docker-compose -f docker-compose.production.yml up -d
```

## 🐛 Troubleshooting

### Container não inicia
```bash
# Ver logs detalhados
docker-compose -f docker-compose.production.yml logs

# Ver logs do container específico
docker logs fidelio-api-prod
docker logs fidelio-web-portal-prod
docker logs fidelio-nginx-prod
```

### Porta 80 já em uso
```bash
# Ver o que está usando a porta
netstat -tulpn | grep :80

# Parar serviço conflitante (se for Apache/Nginx)
systemctl stop apache2
systemctl stop nginx
```

### Rebuild completo
```bash
docker-compose -f docker-compose.production.yml down -v
docker system prune -a
./deploy.sh
```

## 📊 Checklist de Deploy

- [ ] VPS preparada (Docker instalado)
- [ ] Arquivos enviados para /opt/fidelio
- [ ] .env configurado
- [ ] deploy.sh executado
- [ ] Containers rodando (docker-compose ps)
- [ ] Site acessível em http://72.61.41.92
- [ ] API respondendo em http://72.61.41.92/api/health
- [ ] (Opcional) Domínio configurado
- [ ] (Opcional) SSL configurado

## 🎉 Pronto!

Sua aplicação estará rodando em:
- **Web Portal**: http://72.61.41.92
- **API**: http://72.61.41.92/api

Quando tiver o domínio, você pode configurar SSL e terá HTTPS! 🔒
