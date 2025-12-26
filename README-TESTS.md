# Fidelio - Test Documentation

## 🧪 Running Integration Tests

### Quick Start

Execute o script de teste completo:

```powershell
.\test-system.ps1
```

### Opções do Script

```powershell
# Pular a configuração do Docker (usar containers existentes)
.\test-system.ps1 -SkipDocker

# Pular o build (usar binário existente)  
.\test-system.ps1 -SkipBuild

# Modo verbose (mostrar todas as respostas)
.\test-system.ps1 -Verbose

# Combinar opções
.\test-system.ps1 -SkipDocker -Verbose
```

## 📋 Casos de Teste Cobertos

### 1. Health Check
Verifica se a API está respondendo corretamente.

**Endpoint**: `GET /health`

**Esperado**: Status 200

---

### 2. Shadow Wallet - Primeira Transação
Testa a criação de uma shadow wallet para usuário não registrado.

**Endpoint**: `POST /v1/ingest`

**Payload**:
```json
{
  "phone": "+5511987654321",
  "transaction_id": "TEST_SHADOW_001",
  "amount": 25.50
}
```

**Esperado**:
- Shadow balance criada
- TTL de 72 horas configurado
- `is_shadow: true` na resposta

---

### 3. Shadow Wallet - Acumulação
Testa múltiplas transações para mesma shadow wallet.

**Cenário**: 5 transações totalizando 115.50 BRL

**Esperado**:
- Balance acumulado corretamente
- Estado do punch card atualizado (5/5 purchases)
- Reward de 1 ponto concedido

---

### 4. Segurança - API Key Inválida
Testa rejeição de requisições com API key inválida.

**Esperado**: Status 401 Unauthorized

---

### 5. Webhook - Conversão de Shadow Wallet
Simula webhook do Supabase quando usuário faz sign-up.

**Endpoint**: `POST /v1/webhook/user-created`

**Payload**:
```json
{
  "type": "INSERT",
  "table": "users",
  "record": {
    "id": "uuid-do-usuario",
    "phone": "+5511987654321"
  }
}
```

**Esperado**:
- Shadow balance convertida para real wallet
- Estado e pontos migrados
- `converted_at` timestamp atualizado

---

### 6. Stats Endpoint
Verifica endpoint de estatísticas.

**Endpoint**: `GET /v1/stats`

**Esperado**: Métricas do sistema

---

## 🔍 Verificação de Banco de Dados

O script também consulta o banco para verificar:

- **Wallets criadas**: Contagem de wallets reais
- **Shadow balances ativas**: Wallets temporárias ainda não convertidas
- **Shadow balances convertidas**: Wallets migradas com sucesso
- **Transações totais**: Registro no ledger imutável

## 📊 Interpretando Resultados

### Sucesso Total
```
🎉 ALL TESTS PASSED! System is working correctly!
Success Rate: 100%
```

### Falha Parcial
```
⚠️ Some tests failed. Please review the output above.
✓ Tests Passed: 8
✗ Tests Failed: 2
```

## 🐛 Troubleshooting

### PostgreSQL não inicia
```powershell
# Verificar logs do container
docker logs fidelio-postgres

# Reiniciar container
docker-compose restart postgres
```

### Build falha
```powershell
# Ir para o diretório backend
cd backend

# Limpar e rebuildar
go clean
go mod tidy
go build -o fidelio.exe main.go
```

### API não responde
```powershell
# Verificar se a porta 8080 está livre
netstat -ano | findstr :8080

# Verificar logs da aplicação
# (os logs aparecerão no console onde o script foi executado)
```

### Migrations não aplicadas
```powershell
# Aplicar migrations manualmente
docker cp migrations/001_initial_schema.sql fidelio-postgres:/tmp/
docker exec fidelio-postgres psql -U fideliouser -d fideliodb -f /tmp/001_initial_schema.sql
```

## 🔄 Executando Testes Manualmente

Se preferir testar manualmente:

### 1. Iniciar serviços
```powershell
docker-compose up -d postgres
cd backend
go run main.go
```

### 2. Testar endpoint
```powershell
# Health check
curl http://localhost:8080/health

# Ingest transaction
curl -X POST http://localhost:8080/v1/ingest `
  -H "X-API-Key: test_api_key_12345" `
  -H "Content-Type: application/json" `
  -d '{"phone":"+5511999999999","transaction_id":"MANUAL_001","amount":50.0}'
```

### 3. Verificar banco
```powershell
docker exec -it fidelio-postgres psql -U fideliouser -d fideliodb

# Consultas úteis
SELECT * FROM shadow_balances;
SELECT * FROM wallets;
SELECT * FROM transactions ORDER BY created_at DESC LIMIT 10;
```

## 📈 Próximos Passos

Após validar que todos os testes passam:

1. ✅ Fazer commit das mudanças
2. ✅ Push para o repositório GitHub
3. ✅ Configurar ambiente de staging
4. ✅ Integrar com Supabase real
5. ✅ Configurar webhook no Supabase Dashboard
6. ✅ Testar com dados reais (sandbox)
7. ✅ Monitoramento e alertas

## 🎯 Métricas de Qualidade

Para um sistema em produção, considere:

- **Cobertura de testes**: >80%
- **Response time**: <200ms (p95)
- **Taxa de conversão**: >60% (shadow → real wallet)
- **Uptime**: >99.9%
