package config

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

// Config holds all application configuration
type Config struct {
	// Database
	DatabaseURL string

	// Server
	ServerPort string

	// Supabase
	SupabaseURL        string
	SupabaseServiceKey string

	// Webhook
	WebhookSecret string

	// Shadow Wallet
	ShadowWalletTTL time.Duration

	// Worker
	ExpirationWorkerInterval time.Duration

	// Testing
	MockSupabase bool
}

// Load reads configuration from environment variables
func Load() (*Config, error) {
	// Load .env file if it exists
	_ = godotenv.Load()

	cfg := &Config{
		DatabaseURL:        getEnv("DATABASE_URL", ""),
		ServerPort:         getEnv("SERVER_PORT", "8080"),
		SupabaseURL:        getEnv("SUPABASE_URL", ""),
		SupabaseServiceKey: getEnv("SUPABASE_SERVICE_KEY", ""),
		WebhookSecret:      getEnv("WEBHOOK_SECRET", ""),
		MockSupabase:       getEnvAsBool("MOCK_SUPABASE", false),
	}

	// Parse shadow wallet TTL (default: 72 hours)
	shadowTTLHours := getEnvAsInt("SHADOW_WALLET_TTL_HOURS", 72)
	cfg.ShadowWalletTTL = time.Duration(shadowTTLHours) * time.Hour

	// Parse worker interval (default: 1 hour)
	workerIntervalMinutes := getEnvAsInt("EXPIRATION_WORKER_INTERVAL_MINUTES", 60)
	cfg.ExpirationWorkerInterval = time.Duration(workerIntervalMinutes) * time.Minute

	// Validate required fields
	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}

	if cfg.SupabaseURL == "" {
		return nil, fmt.Errorf("SUPABASE_URL is required")
	}

	if cfg.SupabaseServiceKey == "" {
		return nil, fmt.Errorf("SUPABASE_SERVICE_KEY is required")
	}

	return cfg, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvAsInt(key string, defaultValue int) int {
	valueStr := getEnv(key, "")
	if value, err := strconv.Atoi(valueStr); err == nil {
		return value
	}
	return defaultValue
}

func getEnvAsBool(key string, defaultValue bool) bool {
	valueStr := getEnv(key, "")
	if value, err := strconv.ParseBool(valueStr); err == nil {
		return value
	}
	return defaultValue
}
