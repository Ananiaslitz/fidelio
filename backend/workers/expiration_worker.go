package workers

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/Ananiaslitz/fidelio/domain"
	"github.com/Ananiaslitz/fidelio/repository"
)

// ExpirationWorker handles the cleanup of expired shadow balances
type ExpirationWorker struct {
	repo     *repository.Repository
	interval time.Duration
	logger   Logger
}

// Logger interface for structured logging
type Logger interface {
	Info(msg string, fields ...interface{})
	Error(msg string, err error, fields ...interface{})
	Warn(msg string, fields ...interface{})
}

// NewExpirationWorker creates a new expiration worker
func NewExpirationWorker(repo *repository.Repository, interval time.Duration, logger Logger) *ExpirationWorker {
	return &ExpirationWorker{
		repo:     repo,
		interval: interval,
		logger:   logger,
	}
}

// Start begins the expiration worker loop
func (w *ExpirationWorker) Start(ctx context.Context) {
	ticker := time.NewTicker(w.interval)
	defer ticker.Stop()

	w.logger.Info("Expiration worker started", "interval", w.interval)

	// Run immediately on start
	w.processExpiredShadows(ctx)

	for {
		select {
		case <-ctx.Done():
			w.logger.Info("Expiration worker stopped")
			return
		case <-ticker.C:
			w.processExpiredShadows(ctx)
		}
	}
}

// processExpiredShadows finds and processes all expired shadow balances
func (w *ExpirationWorker) processExpiredShadows(ctx context.Context) {
	startTime := time.Now()
	w.logger.Info("Starting expiration processing")

	// Get all expired shadow balances
	expiredShadows, err := w.repo.GetExpiredShadowBalances(ctx)
	if err != nil {
		w.logger.Error("Failed to get expired shadows", err)
		return
	}

	if len(expiredShadows) == 0 {
		w.logger.Info("No expired shadow balances found")
		return
	}

	w.logger.Info("Found expired shadow balances", "count", len(expiredShadows))

	// Group by merchant for statistics
	merchantBreakage := make(map[string]float64)
	successCount := 0
	errorCount := 0

	for _, shadow := range expiredShadows {
		// Create expiration transaction
		if err := w.repo.ExpireShadowBalance(ctx, shadow.ID); err != nil {
			w.logger.Error(
				"Failed to expire shadow balance",
				err,
				"shadow_id", shadow.ID,
				"merchant_id", shadow.MerchantID,
			)
			errorCount++
			continue
		}

		// Track breakage amount per merchant
		merchantID := shadow.MerchantID.String()
		merchantBreakage[merchantID] += shadow.Amount
		successCount++
	}

	// Log breakage statistics
	for merchantID, amount := range merchantBreakage {
		w.logger.Info(
			"Merchant breakage calculated",
			"merchant_id", merchantID,
			"breakage_amount", amount,
			"expired_count", successCount,
		)
	}

	duration := time.Since(startTime)
	w.logger.Info(
		"Expiration processing completed",
		"duration", duration,
		"success_count", successCount,
		"error_count", errorCount,
		"total_breakage", w.sumBreakage(merchantBreakage),
	)
}

// sumBreakage calculates the total breakage amount
func (w *ExpirationWorker) sumBreakage(breakage map[string]float64) float64 {
	total := 0.0
	for _, amount := range breakage {
		total += amount
	}
	return total
}

// SimpleLogger is a basic implementation of the Logger interface
type SimpleLogger struct{}

func (l *SimpleLogger) Info(msg string, fields ...interface{}) {
	log.Printf("[INFO] %s %v", msg, fields)
}

func (l *SimpleLogger) Error(msg string, err error, fields ...interface{}) {
	log.Printf("[ERROR] %s: %v %v", msg, err, fields)
}

func (l *SimpleLogger) Warn(msg string, fields ...interface{}) {
	log.Printf("[WARN] %s %v", msg, fields)
}

// GetMetrics returns current expiration metrics
func (w *ExpirationWorker) GetMetrics(ctx context.Context) (*domain.ExpirationMetrics, error) {
	stats, err := w.repo.GetExpirationMetrics(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get metrics: %w", err)
	}
	return stats, nil
}
