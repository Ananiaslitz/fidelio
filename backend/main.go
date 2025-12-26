package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Ananiaslitz/fidelio/api/handlers"
	"github.com/Ananiaslitz/fidelio/config"
	"github.com/Ananiaslitz/fidelio/domain"
	"github.com/Ananiaslitz/fidelio/repository"
	"github.com/Ananiaslitz/fidelio/services"
	"github.com/Ananiaslitz/fidelio/strategies"
	"github.com/Ananiaslitz/fidelio/workers"

	"github.com/gin-gonic/gin"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq"
)

func main() {
	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Connect to database
	db, err := sqlx.Connect("postgres", cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	// Test database connection
	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}
	log.Println("Database connection established")

	// Initialize repository
	repo := repository.NewRepository(db)

	// Initialize Supabase Auth client
	authClient := services.NewSupabaseAuthClient(cfg.SupabaseURL, cfg.SupabaseServiceKey)

	// Initialize campaign strategies
	strategyRegistry := map[domain.CampaignType]domain.CampaignStrategy{
		domain.CampaignTypePunchCard:   strategies.NewPunchCardStrategy(),
		domain.CampaignTypeCashback:    strategies.NewCashbackStrategy(),
		domain.CampaignTypeProgressive: strategies.NewProgressiveStrategy(),
	}

	// Initialize services
	ingestionEngine := services.NewIngestionEngine(repo, strategyRegistry, authClient, cfg.ShadowWalletTTL)
	conversionService := services.NewConversionService(repo)

	// Initialize workers
	logger := &workers.SimpleLogger{}
	expirationWorker := workers.NewExpirationWorker(repo, cfg.ExpirationWorkerInterval, logger)

	// Start expiration worker in background
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	go expirationWorker.Start(ctx)

	// Initialize HTTP server
	router := setupRouter(repo, ingestionEngine, conversionService, cfg.WebhookSecret)

	srv := &http.Server{
		Addr:    ":" + cfg.ServerPort,
		Handler: router,
	}

	// Start server in goroutine
	go func() {
		log.Printf("Starting Fidelio API server on port %s", cfg.ServerPort)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")

	// Graceful shutdown with 5 second timeout
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer shutdownCancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Fatal("Server forced to shutdown:", err)
	}

	log.Println("Server exited")
}

func setupRouter(repo *repository.Repository, engine *services.IngestionEngine, convService *services.ConversionService, webhookSecret string) *gin.Engine {
	router := gin.Default()

	// Health check
	router.GET("/health", handlers.HealthHandler)

	// API v1 routes
	v1 := router.Group("/v1")
	{
		// Webhook routes (no API key required, uses webhook signature)
		webhookHandler := handlers.NewWebhookHandler(convService, webhookSecret)
		v1.POST("/webhook/user-created", webhookHandler.HandleUserCreated)

		// Protected routes (require API key)
		protected := v1.Group("")
		protected.Use(handlers.AuthMiddleware(repo))
		{
			// Ingestion endpoint
			ingestHandler := handlers.NewIngestHandler(engine, repo)
			protected.POST("/ingest", ingestHandler.Handle)

			// Stats endpoint
			statsHandler := handlers.NewStatsHandler(repo, convService)
			protected.GET("/stats", statsHandler.Handle)
		}
	}

	return router
}
