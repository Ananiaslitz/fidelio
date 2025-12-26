# Fidelio - Deployment Quick Start

## 🚀 Local Development Setup

### Prerequisites
- Go 1.21+
- Docker & Docker Compose
- PostgreSQL (via Docker)
- Supabase account

### Step 1: Clone and Setup

```bash
git clone https://github.com/Ananiaslitz/fidelio.git
cd fidelio/backend

# Copy environment template
cp .env.example .env

# Edit .env with your Supabase credentials
# DATABASE_URL, SUPABASE_URL, SUPABASE_SERVICE_KEY, WEBHOOK_SECRET
```

### Step 2: Start Database

```bash
# Using Docker Compose
docker-compose up -d postgres

# Wait for PostgreSQL to be ready
docker logs -f fidelio-postgres
```

### Step 3: Run Migrations

```bash
# Using Makefile
make migrate

# Or manually
psql $DATABASE_URL < migrations/001_initial_schema.sql
psql $DATABASE_URL < migrations/002_rls_policies.sql
psql $DATABASE_URL < migrations/003_auth_triggers.sql
```

### Step 4: Run Application

```bash
# Development mode
make dev

# Or build and run
make build
./backend/fidelio
```

### Step 5: Test

```bash
# Health check
curl http://localhost:8080/health

# Test ingestion (you'll need to create a merchant and API key first)
curl -X POST http://localhost:8080/v1/ingest \
  -H "X-API-Key: your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"phone": "+5511999999999", "transaction_id": "TEST001", "amount": 100.00}'
```

## 🐳 Docker Deployment

### Build & Run with Docker Compose

```bash
# Build and start all services
make docker-up

# View logs
make docker-logs

# Stop services
make docker-down
```

## 📡 Supabase Webhook Setup

### Configure Auth Webhook

1. Go to Supabase Dashboard → Database → Webhooks
2. Create new webhook:
   - **Name**: User Sign-Up Conversion
   - **Table**: `auth.users`
   - **Events**: `INSERT`
   - **Method**: `POST`
   - **URL**: `https://your-api.com/v1/webhook/user-created`
   - **Headers**: 
     ```
     X-Webhook-Signature: your-webhook-secret
     Content-Type: application/json
     ```

## 🔑 Environment Variables

Required variables in `.env`:

```bash
DATABASE_URL=postgresql://user:pass@host:5432/db
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_KEY=your-service-role-key
WEBHOOK_SECRET=generate-with-openssl-rand-hex-32
SHADOW_WALLET_TTL_HOURS=72
EXPIRATION_WORKER_INTERVAL_MINUTES=60
SERVER_PORT=8080
```

## 📋 Makefile Commands

```bash
make help                 # Show all available commands
make dev                  # Run in development mode
make build                # Build binary
make docker-up            # Start Docker services
make docker-down          # Stop Docker services  
make migrate              # Run database migrations
make clean                # Clean build artifacts
make setup                # Complete local setup
```

## ✅ Verification Checklist

- [ ] Database running (PostgreSQL)
- [ ] Migrations applied successfully
- [ ] `.env` configured with valid credentials
- [ ] Application starts without errors
- [ ] `/health` endpoint returns 200
- [ ] Supabase webhook configured
- [ ] Test ingestion endpoint works

## 🆘 Troubleshooting

### Database Connection Failed
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check connection
psql $DATABASE_URL -c "SELECT 1"
```

### Module Import Errors
```bash
# The module uses GitHub path github.com/Ananiaslitz/fidelio
# Make sure go.mod is correct:
cd backend
go mod tidy
```

### Webhook Not Triggering
- Verify webhook secret matches `.env`
- Check Supabase webhook logs
- Test webhook endpoint manually with curl

## 📚 Next Steps

1. Create merchant via direct database insert or admin API
2. Generate API keys for merchants
3. Configure campaigns (PUNCH_CARD, CASHBACK, or PROGRESSIVE)
4. Start processing transactions!

---

For full documentation, see [`README.md`](./README.md) and [`SHADOW_WALLET_CONVERSION.md`](./docs/SHADOW_WALLET_CONVERSION.md)
