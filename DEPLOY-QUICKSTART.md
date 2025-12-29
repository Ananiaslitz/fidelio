# Guia Rápido de Deploy

## 🖥️ Testar Localmente (Windows)

```powershell
# Executar deploy local
.\deploy.ps1
```

Acesse:
- Web Portal: http://localhost
- API: http://localhost/api

## 🌐 Deploy na VPS (Linux)

### 1. Enviar arquivos para VPS

```powershell
# Via SCP (do Windows)
scp -r d:\DHSA\Ticket user@SEU_IP_VPS:/home/user/fidelio
```

### 2. Na VPS, executar deploy

```bash
cd /home/user/fidelio
chmod +x deploy.sh
./deploy.sh
```

### 3. Configurar SSL (após DNS configurado)

```bash
./setup-ssl.sh
```

## 📝 Checklist Rápido

- [ ] `.env` configurado com credenciais de produção
- [ ] Docker instalado na VPS
- [ ] Arquivos enviados para VPS
- [ ] Executar `./deploy.sh` na VPS
- [ ] Verificar se serviços estão rodando: `docker-compose ps`
- [ ] (Opcional) Configurar domínio e SSL

## 🔧 Comandos Úteis

```bash
# Ver logs
docker-compose -f docker-compose.production.yml logs -f

# Status
docker-compose -f docker-compose.production.yml ps

# Restart
docker-compose -f docker-compose.production.yml restart

# Parar tudo
docker-compose -f docker-compose.production.yml down
```

## 💡 Dicas

1. **Domínio**: Pode usar IP temporariamente, depois atualiza `DOMAIN` no `.env`
2. **SSL**: Só configure após o domínio estar apontando para o servidor
3. **Backup**: Faça backup do `.env` (mas NÃO commite no Git!)
4. **Segurança**: Troque as senhas padrão no `.env`

Para mais detalhes, veja [DEPLOY-PRODUCTION.md](file:///d:/DHSA/Ticket/DEPLOY-PRODUCTION.md)
