.PHONY: help build run test clean migrate migrate-up migrate-down docker-build docker-up docker-down dev

# Variables
BINARY_NAME=fidelio
GO_FILES=$(shell find backend -name '*.go')
DOCKER_IMAGE=fidelio-api
DATABASE_URL?=postgresql://fidelio:fidelio_dev_password@localhost:5432/fidelio?sslmode=disable

# Default target
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development
dev: ## Run application in development mode
	cd backend && go run main.go

build: ## Build the Go binary
	cd backend && go build -o $(BINARY_NAME) main.go

run: build ## Build and run the binary
	cd backend && ./$(BINARY_NAME)

clean: ## Clean build artifacts
	cd backend && rm -f $(BINARY_NAME)
	cd backend && go clean

# Dependencies
deps: ## Download Go dependencies
	cd backend && go mod download
	cd backend && go mod tidy

# Database migrations
migrate: ## Run all migrations
	@echo "Running migrations..."
	@PGPASSWORD=fidelio_dev_password psql -h localhost -U fidelio -d fidelio -f migrations/001_initial_schema.sql
	@PGPASSWORD=fidelio_dev_password psql -h localhost -U fidelio -d fidelio -f migrations/002_rls_policies.sql
	@PGPASSWORD=fidelio_dev_password psql -h localhost -U fidelio -d fidelio -f migrations/003_auth_triggers.sql
	@echo "Migrations completed!"

migrate-up: ## Run migrations (alias)
	@$(MAKE) migrate

migrate-down: ## Rollback migrations (warning: drops all tables)
	@echo "WARNING: This will drop all tables!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		PGPASSWORD=fidelio_dev_password psql -h localhost -U fidelio -d fidelio -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"; \
		echo "Database reset!"; \
	fi

# Docker commands
docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE) .

docker-up: ## Start all services with Docker Compose
	docker-compose up -d

docker-down: ## Stop all services
	docker-compose down

docker-logs: ## View Docker logs
	docker-compose logs -f api

docker-shell: ## Open shell in API container
	docker exec -it fidelio-api /bin/sh

docker-psql: ## Open PostgreSQL shell
	docker exec -it fidelio-postgres psql -U fidelio -d fidelio

# Complete local setup
setup: ## Complete local setup (Docker + migrations)
	@echo "Starting Fidelio local environment..."
	docker-compose up -d postgres
	@echo "Waiting for PostgreSQL to be ready..."
	@sleep 5
	@$(MAKE) migrate
	@echo "Setup complete! Run 'make dev' to start the API."

# Code quality
fmt: ## Format Go code
	cd backend && go fmt ./...

vet: ## Run Go vet
	cd backend && go vet ./...

lint: fmt vet ## Run all linters

# API testing (manual)
test-health: ## Test health endpoint
	curl http://localhost:8080/health

test-ingest: ## Test ingest endpoint (requires API key)
	curl -X POST http://localhost:8080/v1/ingest \
		-H "X-API-Key: test_key_123" \
		-H "Content-Type: application/json" \
		-d '{"phone": "+5511999999999", "transaction_id": "TEST001", "amount": 100.00}'

# Production
prod-build: ## Build for production
	cd backend && CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o $(BINARY_NAME) main.go

# Complete reset
reset: docker-down clean ## Complete reset (stop containers, clean builds)
	docker-compose down -v
	@echo "Environment reset complete!"
