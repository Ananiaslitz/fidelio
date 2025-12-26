package services

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/Ananiaslitz/fidelio/domain"
	"github.com/Ananiaslitz/fidelio/repository"

	"github.com/google/uuid"
)

// ConversionService handles the migration of shadow wallets to real wallets
type ConversionService struct {
	repo *repository.Repository
}

// NewConversionService creates a new conversion service
func NewConversionService(repo *repository.Repository) *ConversionService {
	return &ConversionService{
		repo: repo,
	}
}

// ConvertShadowToRealWallet migrates all shadow balances for a phone to a real wallet
// This is triggered when a user signs up in Supabase Auth
func (c *ConversionService) ConvertShadowToRealWallet(
	ctx context.Context,
	userID uuid.UUID,
	phoneHash string,
) error {
	// Begin transaction for atomic conversion
	tx, err := c.repo.BeginTx(ctx)
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Get all active shadow balances for this phone hash
	shadows, err := c.repo.GetActiveShadowBalancesByPhone(ctx, phoneHash)
	if err != nil {
		return fmt.Errorf("failed to get shadow balances: %w", err)
	}

	if len(shadows) == 0 {
		// No shadow balances to convert
		return nil
	}

	// Process each shadow balance (one per merchant)
	for _, shadow := range shadows {
		// Get or create real wallet for this merchant
		wallet, err := c.repo.GetOrCreateWalletWithTx(ctx, tx, shadow.MerchantID, userID, phoneHash)
		if err != nil {
			return fmt.Errorf("failed to get/create wallet for merchant %s: %w", shadow.MerchantID, err)
		}

		// Merge shadow state with existing wallet state
		mergedState, err := c.mergeStates(wallet.State, shadow.State)
		if err != nil {
			return fmt.Errorf("failed to merge states: %w", err)
		}

		// Transfer balance and state to real wallet
		newBalance := wallet.Balance + shadow.Amount
		if err := c.repo.UpdateWalletWithTx(ctx, tx, wallet.ID, newBalance, mergedState); err != nil {
			return fmt.Errorf("failed to update wallet: %w", err)
		}

		// Mark shadow balance as converted
		if err := c.repo.MarkShadowAsConvertedWithTx(ctx, tx, shadow.ID); err != nil {
			return fmt.Errorf("failed to mark shadow as converted: %w", err)
		}

		// Create a CONVERT transaction record
		convertTx := &domain.Transaction{
			ID:              uuid.New(),
			MerchantID:      shadow.MerchantID,
			WalletID:        &wallet.ID,
			ShadowBalanceID: &shadow.ID,
			Type:            domain.TransactionTypeConvert,
			Amount:          shadow.Amount,
			Metadata:        json.RawMessage(fmt.Sprintf(`{"converted_from_shadow":"%s","conversion_date":"%s"}`, shadow.ID, time.Now().Format(time.RFC3339))),
			CreatedAt:       time.Now(),
		}

		if err := c.repo.CreateTransactionWithTx(ctx, tx, convertTx); err != nil {
			return fmt.Errorf("failed to create conversion transaction: %w", err)
		}
	}

	// Commit the transaction
	if err := tx.Commit(); err != nil {
		return fmt.Errorf("failed to commit conversion: %w", err)
	}

	return nil
}

// mergeStates intelligently merges shadow state with existing wallet state
// This ensures we don't lose progress when converting
func (c *ConversionService) mergeStates(walletState, shadowState json.RawMessage) (json.RawMessage, error) {
	// If wallet has no state, use shadow state
	if len(walletState) == 0 || string(walletState) == "{}" {
		return shadowState, nil
	}

	// If shadow has no state, keep wallet state
	if len(shadowState) == 0 || string(shadowState) == "{}" {
		return walletState, nil
	}

	// Parse both states
	var walletData map[string]interface{}
	var shadowData map[string]interface{}

	if err := json.Unmarshal(walletState, &walletData); err != nil {
		return nil, fmt.Errorf("failed to parse wallet state: %w", err)
	}

	if err := json.Unmarshal(shadowState, &shadowData); err != nil {
		return nil, fmt.Errorf("failed to parse shadow state: %w", err)
	}

	// Merge strategy: Add numeric values, keep max for counts
	merged := make(map[string]interface{})

	// Copy wallet state
	for k, v := range walletData {
		merged[k] = v
	}

	// Merge shadow state
	for k, v := range shadowData {
		if existing, exists := merged[k]; exists {
			// If both are numbers, add them
			if vNum, ok := v.(float64); ok {
				if existNum, ok := existing.(float64); ok {
					merged[k] = existNum + vNum
					continue
				}
			}
		}
		// Otherwise, take shadow value if wallet doesn't have it
		if _, exists := merged[k]; !exists {
			merged[k] = v
		}
	}

	// Serialize merged state
	result, err := json.Marshal(merged)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal merged state: %w", err)
	}

	return result, nil
}

// GetConversionStats returns statistics about shadow wallet conversions
func (c *ConversionService) GetConversionStats(ctx context.Context, merchantID uuid.UUID) (*domain.ConversionStats, error) {
	stats, err := c.repo.GetConversionStats(ctx, merchantID)
	if err != nil {
		return nil, fmt.Errorf("failed to get conversion stats: %w", err)
	}
	return stats, nil
}
