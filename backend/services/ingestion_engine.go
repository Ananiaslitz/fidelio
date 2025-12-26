package services

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"time"

	"github.com/Ananiaslitz/fidelio/domain"
	"github.com/Ananiaslitz/fidelio/repository"

	"github.com/google/uuid"
)

// IngestionEngine orchestrates the transaction ingestion process
type IngestionEngine struct {
	repo               *repository.Repository
	strategyRegistry   map[domain.CampaignType]domain.CampaignStrategy
	shadowWalletTTL    time.Duration
	supabaseAuthClient SupabaseAuthClient
}

// SupabaseAuthClient interface for checking user existence
type SupabaseAuthClient interface {
	UserExistsByPhone(ctx context.Context, phone string) (userID *uuid.UUID, exists bool, err error)
}

// NewIngestionEngine creates a new ingestion engine
func NewIngestionEngine(
	repo *repository.Repository,
	strategies map[domain.CampaignType]domain.CampaignStrategy,
	authClient SupabaseAuthClient,
	shadowTTL time.Duration,
) *IngestionEngine {
	return &IngestionEngine{
		repo:               repo,
		strategyRegistry:   strategies,
		shadowWalletTTL:    shadowTTL,
		supabaseAuthClient: authClient,
	}
}

// ProcessTransaction is the main entry point for transaction ingestion
func (e *IngestionEngine) ProcessTransaction(
	ctx context.Context,
	merchant *domain.Merchant,
	request *domain.IngestRequest,
) (*domain.IngestResponse, error) {
	// Get active campaign for this merchant
	campaign, err := e.repo.GetActiveCampaign(ctx, merchant.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to get active campaign: %w", err)
	}

	// Get the appropriate strategy
	strategy, ok := e.strategyRegistry[campaign.Type]
	if !ok {
		return nil, fmt.Errorf("no strategy found for campaign type: %s", campaign.Type)
	}

	// Hash the phone number for privacy
	phoneHash := e.hashPhone(request.Phone)

	// Check if user exists in Supabase Auth
	userID, userExists, err := e.supabaseAuthClient.UserExistsByPhone(ctx, request.Phone)
	if err != nil {
		return nil, fmt.Errorf("failed to check user existence: %w", err)
	}

	if userExists && userID != nil {
		// Process with real wallet
		return e.processRealWallet(ctx, merchant, campaign, strategy, *userID, phoneHash, request)
	}

	// Process with shadow wallet
	return e.processShadowWallet(ctx, merchant, campaign, strategy, phoneHash, request)
}

// processRealWallet handles transactions for registered users
func (e *IngestionEngine) processRealWallet(
	ctx context.Context,
	merchant *domain.Merchant,
	campaign *domain.Campaign,
	strategy domain.CampaignStrategy,
	userID uuid.UUID,
	phoneHash string,
	request *domain.IngestRequest,
) (*domain.IngestResponse, error) {
	// Get or create wallet
	wallet, err := e.repo.GetOrCreateWallet(ctx, merchant.ID, userID, phoneHash)
	if err != nil {
		return nil, fmt.Errorf("failed to get/create wallet: %w", err)
	}

	// Execute strategy
	input := &domain.StrategyInput{
		Campaign:      campaign,
		TransactionID: request.TransactionID,
		Amount:        request.Amount,
		CurrentState:  wallet.State,
		Metadata:      request.Metadata,
	}

	result, err := strategy.Execute(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("strategy execution failed: %w", err)
	}

	// Update wallet in transaction
	tx, err := e.repo.BeginTx(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Update wallet balance and state
	newBalance := wallet.Balance + result.NewBalance
	if err := e.repo.UpdateWalletWithTx(ctx, tx, wallet.ID, newBalance, result.NewState); err != nil {
		return nil, fmt.Errorf("failed to update wallet: %w", err)
	}

	// Record transaction in ledger
	ledgerTx := &domain.Transaction{
		ID:         uuid.New(),
		MerchantID: merchant.ID,
		CampaignID: &campaign.ID,
		WalletID:   &wallet.ID,
		Type:       domain.TransactionTypeEarn,
		Amount:     result.NewBalance,
		Metadata:   request.Metadata,
		CreatedAt:  time.Now(),
	}

	if err := e.repo.CreateTransactionWithTx(ctx, tx, ledgerTx); err != nil {
		return nil, fmt.Errorf("failed to create transaction: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return &domain.IngestResponse{
		Success:    true,
		NewBalance: newBalance,
		IsShadow:   false,
		Reward:     result.RewardEarned,
		Message:    "Transação processada com sucesso!",
	}, nil
}

// processShadowWallet handles transactions for unregistered users
func (e *IngestionEngine) processShadowWallet(
	ctx context.Context,
	merchant *domain.Merchant,
	campaign *domain.Campaign,
	strategy domain.CampaignStrategy,
	phoneHash string,
	request *domain.IngestRequest,
) (*domain.IngestResponse, error) {
	// Get or create shadow balance
	shadow, err := e.repo.GetOrCreateShadowBalance(ctx, merchant.ID, phoneHash, e.shadowWalletTTL)
	if err != nil {
		return nil, fmt.Errorf("failed to get/create shadow balance: %w", err)
	}

	// Check if already expired
	if time.Now().After(shadow.ExpiresAt) {
		return nil, fmt.Errorf("shadow wallet expired")
	}

	// Execute strategy
	input := &domain.StrategyInput{
		Campaign:      campaign,
		TransactionID: request.TransactionID,
		Amount:        request.Amount,
		CurrentState:  shadow.State,
		Metadata:      request.Metadata,
	}

	result, err := strategy.Execute(ctx, input)
	if err != nil {
		return nil, fmt.Errorf("strategy execution failed: %w", err)
	}

	// Update shadow balance in transaction
	tx, err := e.repo.BeginTx(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to begin transaction: %w", err)
	}
	defer tx.Rollback()

	// Update shadow balance and state
	newAmount := shadow.Amount + result.NewBalance
	if err := e.repo.UpdateShadowBalanceWithTx(ctx, tx, shadow.ID, newAmount, result.NewState); err != nil {
		return nil, fmt.Errorf("failed to update shadow balance: %w", err)
	}

	// Record transaction in ledger
	ledgerTx := &domain.Transaction{
		ID:              uuid.New(),
		MerchantID:      merchant.ID,
		CampaignID:      &campaign.ID,
		ShadowBalanceID: &shadow.ID,
		Type:            domain.TransactionTypeEarn,
		Amount:          result.NewBalance,
		Metadata:        request.Metadata,
		CreatedAt:       time.Now(),
	}

	if err := e.repo.CreateTransactionWithTx(ctx, tx, ledgerTx); err != nil {
		return nil, fmt.Errorf("failed to create transaction: %w", err)
	}

	if err := tx.Commit(); err != nil {
		return nil, fmt.Errorf("failed to commit transaction: %w", err)
	}

	return &domain.IngestResponse{
		Success:    true,
		NewBalance: newAmount,
		IsShadow:   true,
		ExpiresAt:  &shadow.ExpiresAt,
		Reward:     result.RewardEarned,
		Message:    fmt.Sprintf("Saldo temporário criado! Cadastre-se até %s para não perder seus benefícios.", shadow.ExpiresAt.Format("02/01/2006 15:04")),
	}, nil
}

// hashPhone creates a SHA-256 hash of the phone number
func (e *IngestionEngine) hashPhone(phone string) string {
	hash := sha256.Sum256([]byte(phone))
	return hex.EncodeToString(hash[:])
}
