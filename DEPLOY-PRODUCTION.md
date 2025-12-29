# Fidelio - Production Deployment Guide

## 📋 Pré-requisitos

1. **VPS com Ubuntu/Debian** (recomendado Ubuntu 22.04 LTS)
2. **Docker e Docker Compose instalados**
3. **Domínio configurado** (opcional, pode usar IP temporariamente)
4. **Portas abertas**: 80 (HTTP), 443 (HTTPS), 5432 (PostgreSQL - opcional)

## 🚀 Deploy Rápido

### 1. Preparar o Servidor

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Instalar Docker Compose
sudo apt install docker-compose -y

# Adicionar usuário ao grupo docker
sudo usermod -aG docker $USER
newgrp docker
```

### 2. Clonar/Enviar o Projeto

```bash
# Opção 1: Via Git
git clone <seu-repositorio>
cd Ticket

# Opção 2: Via SCP (do seu computador local)
scp -r d:\DHSA\Ticket user@your-vps-ip:/home/user/
```

### 3. Configurar Variáveis de Ambiente

```bash
# Copiar template
cp .env.production.example .env.production

# Editar com suas credenciais
nano .env.production
```

**Importante**: Configure estas variáveis:
- `DOMAIN` - Seu domínio ou IP da VPS
- `POSTGRES_PASSWORD` - Senha forte para o banco
- `SUPABASE_URL` e `SUPABASE_SERVICE_KEY` - Suas credenciais Supabase
- `WEBHOOK_SECRET` - Gere com: `openssl rand -hex 32`
- `CERTBOT_EMAIL` - Seu email (para SSL)

### 4. Deploy!

```bash
# Dar permissão de execução
chmod +x deploy.sh setup-ssl.sh

# Executar deploy
./deploy.sh
```

Pronto! Sua aplicação estará rodando em:
- **Web Portal**: `http://SEU_IP` ou `http://SEU_DOMINIO`
- **API**: `http://SEU_IP/api` ou `http://SEU_DOMINIO/api`

### 5. Configurar SSL/HTTPS (Opcional, mas Recomendado)

```bash
# Certifique-se que seu domínio aponta para o servidor
# Depois execute:
./setup-ssl.sh
```

Após isso, sua aplicação estará disponível em HTTPS! 🔒

## 📊 Comandos Úteis

### Ver logs
```bash
docker-compose -f docker-compose.production.yml logs -f

# Logs de um serviço específico
docker-compose -f docker-compose.production.yml logs -f api
docker-compose -f docker-compose.production.yml logs -f web-portal
```

### Status dos containers
```bash
docker-compose -f docker-compose.production.yml ps
```

### Reiniciar serviços
```bash
docker-compose -f docker-compose.production.yml restart
```

### Parar tudo
```bash
docker-compose -f docker-compose.production.yml down
```

### Atualizar aplicação
```bash
git pull  # Se usando Git
./deploy.sh
```

### Backup do banco de dados
```bash
docker exec fidelio-postgres-prod pg_dump -U fidelio_prod fidelio_production > backup.sql
```

### Restaurar banco de dados
```bash
cat backup.sql | docker exec -i fidelio-postgres-prod psql -U fidelio_prod fidelio_production
```

## 🔧 Troubleshooting

### Containers não iniciam
```bash
# Ver logs detalhados
docker-compose -f docker-compose.production.yml logs

# Verificar se portas estão em uso
sudo netstat -tulpn | grep -E '80|443|5432'
```

### Erro de conexão com banco
```bash
# Verificar se PostgreSQL está healthy
docker-compose -f docker-compose.production.yml ps

# Ver logs do PostgreSQL
docker-compose -f docker-compose.production.yml logs postgres
```

### SSL não funciona
```bash
# Verificar se domínio aponta para o servidor
nslookup SEU_DOMINIO

# Verificar certificados
docker-compose -f docker-compose.production.yml exec certbot certbot certificates
```

## 🔐 Segurança

1. **Firewall**: Configure UFW para permitir apenas portas necessárias
```bash
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

2. **Senhas fortes**: Use senhas complexas no `.env.production`

3. **Atualizações**: Mantenha o sistema e Docker atualizados
```bash
sudo apt update && sudo apt upgrade -y
```

4. **Backups**: Configure backups automáticos do banco de dados

## 📁 Estrutura de Arquivos

```
Ticket/
├── docker-compose.production.yml  # Configuração Docker produção
├── .env.production                # Variáveis de ambiente (NÃO commitar!)
├── deploy.sh                      # Script de deploy
├── setup-ssl.sh                   # Script SSL
├── nginx/
│   ├── nginx.conf                 # Configuração principal Nginx
│   └── conf.d/
│       └── default.conf           # Reverse proxy config
├── backend/                       # Código Go API
├── web-portal/                    # Código React
└── migrations/                    # Migrações SQL
```

## 🎯 Próximos Passos

1. ✅ Deploy básico funcionando
2. 🔒 Configurar SSL/HTTPS
3. 📊 Configurar monitoramento (Grafana/Prometheus)
4. 🔄 Setup CI/CD (GitHub Actions)
5. 📧 Configurar alertas de erro
6. 💾 Backups automáticos

## 💡 Dicas

- Use um domínio `.cloud` quando decidir o nome final
- Configure DNS antes de rodar `setup-ssl.sh`
- Monitore logs regularmente: `docker-compose logs -f`
- Faça backups antes de atualizações importantes
