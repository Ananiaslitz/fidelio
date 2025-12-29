package repository

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/Ananiaslitz/fidelio/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// Repository handles all database operations
type Repository struct {
	db *sqlx.DB
}

// NewRepository creates a new repository instance
func NewRepository(db *sqlx.DB) *Repository {
	return &Repository{db: db}
}

// BeginTx starts a new database transaction
func (r *Repository) BeginTx(ctx context.Context) (*sqlx.Tx, error) {
	return r.db.BeginTxx(ctx, nil)
}

// Merchant operations

func (r *Repository) GetMerchantByAPIKey(ctx context.Context, apiKey string) (*domain.Merchant, error) {
	var merchant domain.Merchant
	query := `SELECT * FROM merchants WHERE api_key = $1`
	if err := r.db.GetContext(ctx, &merchant, query, apiKey); err != nil {
		return nil, err
	}
	return &merchant, nil
}

func (r *Repository) GetMerchantByEmail(ctx context.Context, email string) (*domain.Merchant, error) {
	var merchant domain.Merchant
	query := `SELECT * FROM merchants WHERE settings->>'email' = $1`

	println("=== REPOSITORY QUERY ===")
	println("Query:", query)
	println("Email param:", email)

	if err := r.db.GetContext(ctx, &merchant, query, email); err != nil {
		println("Query ERROR:", err.Error())
		return nil, err
	}

	println("Query SUCCESS: Found merchant ID:", merchant.ID.String())
	return &merchant, nil
}

// Campaign operations

func (r *Repository) GetActiveCampaign(ctx context.Context, merchantID uuid.UUID) (*domain.Campaign, error) {
	var campaign domain.Campaign
	query := `
		SELECT * FROM campaigns 
		WHERE merchant_id = $1 
		AND is_active = true 
		AND (starts_at IS NULL OR starts_at <= NOW())
		AND (ends_at IS NULL OR ends_at >= NOW())
		ORDER BY created_at DESC 
		LIMIT 1
	`
	if err := r.db.GetContext(ctx, &campaign, query, merchantID); err != nil {
		return nil, err
	}
	return &campaign, nil
}

// Wallet operations

func (r *Repository) GetOrCreateWallet(ctx context.Context, merchantID, userID uuid.UUID, phoneHash string) (*domain.Wallet, error) {
	var wallet domain.Wallet

	// Try to get existing wallet
	query := `SELECT * FROM wallets WHERE merchant_id = $1 AND user_id = $2`
	err := r.db.GetContext(ctx, &wallet, query, merchantID, userID)
	if err == nil {
		return &wallet, nil
	}

	if err != sql.ErrNoRows {
		return nil, err
	}

	// Create new wallet
	wallet = domain.Wallet{
		ID:         uuid.New(),
		MerchantID: merchantID,
		UserID:     userID,
		PhoneHash:  phoneHash,
		Balance:    0,
		State:      json.RawMessage("{}"),
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}

	insertQuery := `
		INSERT INTO wallets (id, merchant_id, user_id, phone_hash, balance, state, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err = r.db.ExecContext(ctx, insertQuery,
		wallet.ID, wallet.MerchantID, wallet.UserID, wallet.PhoneHash,
		wallet.Balance, wallet.State, wallet.CreatedAt, wallet.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &wallet, nil
}

func (r *Repository) GetOrCreateWalletWithTx(ctx context.Context, tx *sqlx.Tx, merchantID, userID uuid.UUID, phoneHash string) (*domain.Wallet, error) {
	var wallet domain.Wallet

	query := `SELECT * FROM wallets WHERE merchant_id = $1 AND user_id = $2`
	err := tx.GetContext(ctx, &wallet, query, merchantID, userID)
	if err == nil {
		return &wallet, nil
	}

	if err != sql.ErrNoRows {
		return nil, err
	}

	wallet = domain.Wallet{
		ID:         uuid.New(),
		MerchantID: merchantID,
		UserID:     userID,
		PhoneHash:  phoneHash,
		Balance:    0,
		State:      json.RawMessage("{}"),
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}

	insertQuery := `
		INSERT INTO wallets (id, merchant_id, user_id, phone_hash, balance, state, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
	`
	_, err = tx.ExecContext(ctx, insertQuery,
		wallet.ID, wallet.MerchantID, wallet.UserID, wallet.PhoneHash,
		wallet.Balance, wallet.State, wallet.CreatedAt, wallet.UpdatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &wallet, nil
}

func (r *Repository) UpdateWalletWithTx(ctx context.Context, tx *sqlx.Tx, walletID uuid.UUID, newBalance float64, newState json.RawMessage) error {
	query := `UPDATE wallets SET balance = $1, state = $2, updated_at = $3 WHERE id = $4`
	_, err := tx.ExecContext(ctx, query, newBalance, newState, time.Now(), walletID)
	return err
}

// Shadow Balance operations

func (r *Repository) GetOrCreateShadowBalance(ctx context.Context, merchantID uuid.UUID, phoneHash string, ttl time.Duration) (*domain.ShadowBalance, error) {
	var shadow domain.ShadowBalance

	query := `SELECT * FROM shadow_balances WHERE merchant_id = $1 AND phone_hash = $2 AND converted_at IS NULL`
	err := r.db.GetContext(ctx, &shadow, query, merchantID, phoneHash)
	if err == nil {
		return &shadow, nil
	}

	if err != sql.ErrNoRows {
		return nil, err
	}

	shadow = domain.ShadowBalance{
		ID:         uuid.New(),
		MerchantID: merchantID,
		PhoneHash:  phoneHash,
		Amount:     0,
		State:      json.RawMessage("{}"),
		ExpiresAt:  time.Now().Add(ttl),
		CreatedAt:  time.Now(),
	}

	insertQuery := `
		INSERT INTO shadow_balances (id, merchant_id, phone_hash, amount, state, expires_at, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
	`
	_, err = r.db.ExecContext(ctx, insertQuery,
		shadow.ID, shadow.MerchantID, shadow.PhoneHash,
		shadow.Amount, shadow.State, shadow.ExpiresAt, shadow.CreatedAt,
	)
	if err != nil {
		return nil, err
	}

	return &shadow, nil
}

func (r *Repository) UpdateShadowBalanceWithTx(ctx context.Context, tx *sqlx.Tx, shadowID uuid.UUID, newAmount float64, newState json.RawMessage) error {
	query := `UPDATE shadow_balances SET amount = $1, state = $2 WHERE id = $3`
	_, err := tx.ExecContext(ctx, query, newAmount, newState, shadowID)
	return err
}

func (r *Repository) GetActiveShadowBalancesByPhone(ctx context.Context, phoneHash string) ([]*domain.ShadowBalance, error) {
	var shadows []*domain.ShadowBalance
	query := `
		SELECT * FROM shadow_balances 
		WHERE phone_hash = $1 
		AND converted_at IS NULL 
		AND expires_at > NOW()
	`
	err := r.db.SelectContext(ctx, &shadows, query, phoneHash)
	return shadows, err
}

func (r *Repository) MarkShadowAsConvertedWithTx(ctx context.Context, tx *sqlx.Tx, shadowID uuid.UUID) error {
	query := `UPDATE shadow_balances SET converted_at = $1 WHERE id = $2`
	_, err := tx.ExecContext(ctx, query, time.Now(), shadowID)
	return err
}

func (r *Repository) GetExpiredShadowBalances(ctx context.Context) ([]*domain.ShadowBalance, error) {
	var shadows []*domain.ShadowBalance
	query := `
		SELECT * FROM shadow_balances 
		WHERE converted_at IS NULL 
		AND expires_at <= NOW()
	`
	err := r.db.SelectContext(ctx, &shadows, query)
	return shadows, err
}

func (r *Repository) ExpireShadowBalance(ctx context.Context, shadowID uuid.UUID) error {
	tx, err := r.BeginTx(ctx)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	// Get shadow balance
	var shadow domain.ShadowBalance
	query := `SELECT * FROM shadow_balances WHERE id = $1`
	if err := tx.GetContext(ctx, &shadow, query, shadowID); err != nil {
		return err
	}

	// Create expiration transaction
	expireTx := &domain.Transaction{
		ID:              uuid.New(),
		MerchantID:      shadow.MerchantID,
		ShadowBalanceID: &shadow.ID,
		Type:            domain.TransactionTypeExpire,
		Amount:          -shadow.Amount, // Negative to represent breakage
		Metadata:        json.RawMessage(fmt.Sprintf(`{"expired_at":"%s"}`, time.Now().Format(time.RFC3339))),
		CreatedAt:       time.Now(),
	}

	if err := r.CreateTransactionWithTx(ctx, tx, expireTx); err != nil {
		return err
	}

	// Mark as converted (with null user_id to indicate expiration)
	if err := r.MarkShadowAsConvertedWithTx(ctx, tx, shadowID); err != nil {
		return err
	}

	return tx.Commit()
}

// Transaction operations

func (r *Repository) CreateTransactionWithTx(ctx context.Context, tx *sqlx.Tx, transaction *domain.Transaction) error {
	query := `
		INSERT INTO transactions (id, merchant_id, campaign_id, wallet_id, shadow_balance_id, transaction_type, amount, metadata, created_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := tx.ExecContext(ctx, query,
		transaction.ID, transaction.MerchantID, transaction.CampaignID,
		transaction.WalletID, transaction.ShadowBalanceID, transaction.Type,
		transaction.Amount, transaction.Metadata, transaction.CreatedAt,
	)
	return err
}

// Statistics operations

func (r *Repository) GetConversionStats(ctx context.Context, merchantID uuid.UUID) (*domain.ConversionStats, error) {
	var stats domain.ConversionStats

	query := `
		SELECT 
			COUNT(*) as total_shadow_balances,
			COUNT(CASE WHEN converted_at IS NOT NULL THEN 1 END) as converted_balances,
			COUNT(CASE WHEN converted_at IS NOT NULL AND expires_at < converted_at THEN 1 END) as expired_balances,
			COUNT(CASE WHEN converted_at IS NULL AND expires_at > NOW() THEN 1 END) as active_shadow_balances,
			COALESCE(SUM(CASE WHEN converted_at IS NOT NULL THEN amount ELSE 0 END), 0) as total_converted_amount,
			COALESCE(SUM(CASE WHEN converted_at IS NULL AND expires_at <= NOW() THEN amount ELSE 0 END), 0) as total_breakage_amount
		FROM shadow_balances
		WHERE merchant_id = $1
	`

	err := r.db.GetContext(ctx, &stats, query, merchantID)
	if err != nil {
		return nil, err
	}

	if stats.TotalShadowBalances > 0 {
		stats.ConversionRate = float64(stats.ConvertedBalances) / float64(stats.TotalShadowBalances) * 100
	}

	return &stats, nil
}

func (r *Repository) GetExpirationMetrics(ctx context.Context) (*domain.ExpirationMetrics, error) {
	var metrics domain.ExpirationMetrics

	query := `
		SELECT 
			COUNT(*) as total_expired,
			COALESCE(SUM(amount), 0) as total_breakage
		FROM shadow_balances
		WHERE converted_at IS NOT NULL AND expires_at < converted_at
	`

	var totalExpired int64
	var totalBreakage float64

	err := r.db.QueryRowContext(ctx, query).Scan(&totalExpired, &totalBreakage)
	if err != nil {
		return nil, err
	}

	metrics.TotalExpired = totalExpired
	metrics.TotalBreakage = totalBreakage
	if totalExpired > 0 {
		metrics.AverageBreakage = totalBreakage / float64(totalExpired)
	}

	return &metrics, nil
}

// Campaign CRUD operations

func (r *Repository) CreateCampaign(ctx context.Context, campaign *domain.Campaign) error {
	query := `
		INSERT INTO campaigns (id, merchant_id, name, type, config, is_active, starts_at, ends_at, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
	`
	_, err := r.db.ExecContext(ctx, query,
		campaign.ID, campaign.MerchantID, campaign.Name, campaign.Type,
		campaign.Config, campaign.IsActive, campaign.StartsAt, campaign.EndsAt,
		campaign.CreatedAt, campaign.UpdatedAt,
	)
	return err
}

func (r *Repository) GetCampaignsByMerchant(ctx context.Context, merchantID uuid.UUID) ([]*domain.Campaign, error) {
	var campaigns []*domain.Campaign
	query := `SELECT * FROM campaigns WHERE merchant_id = $1 ORDER BY created_at DESC`
	err := r.db.SelectContext(ctx, &campaigns, query, merchantID)
	return campaigns, err
}

func (r *Repository) GetCampaignByID(ctx context.Context, campaignID uuid.UUID) (*domain.Campaign, error) {
	var campaign domain.Campaign
	query := `SELECT * FROM campaigns WHERE id = $1`
	err := r.db.GetContext(ctx, &campaign, query, campaignID)
	if err != nil {
		return nil, err
	}
	return &campaign, nil
}

func (r *Repository) UpdateCampaign(ctx context.Context, campaign *domain.Campaign) error {
	query := `
		UPDATE campaigns 
		SET name = $1, type = $2, config = $3, is_active = $4, starts_at = $5, ends_at = $6, updated_at = $7
		WHERE id = $8
	`
	_, err := r.db.ExecContext(ctx, query,
		campaign.Name, campaign.Type, campaign.Config, campaign.IsActive,
		campaign.StartsAt, campaign.EndsAt, campaign.UpdatedAt, campaign.ID,
	)
	return err
}

func (r *Repository) DeleteCampaign(ctx context.Context, campaignID uuid.UUID) error {
	query := `DELETE FROM campaigns WHERE id = $1`
	_, err := r.db.ExecContext(ctx, query, campaignID)
	return err
}

// Plan operations

func (r *Repository) GetPlanBySlug(ctx context.Context, slug string) (*domain.Plan, error) {
	var plan domain.Plan
	query := `SELECT * FROM plans WHERE slug = $1 AND is_active = TRUE`
	err := r.db.GetContext(ctx, &plan, query, slug)
	if err != nil {
		return nil, err
	}
	return &plan, nil
}

func (r *Repository) GetAllActivePlans(ctx context.Context) ([]*domain.Plan, error) {
	var plans []*domain.Plan
	query := `SELECT * FROM plans WHERE is_active = TRUE ORDER BY price_monthly ASC`
	err := r.db.SelectContext(ctx, &plans, query)
	return plans, err
}

// Subscription operations

func (r *Repository) GetMerchantSubscription(ctx context.Context, merchantID uuid.UUID) (*domain.Subscription, error) {
	var subscription domain.Subscription
	query := `
		SELECT s.* FROM subscriptions s
		WHERE s.merchant_id = $1 AND s.status = 'active'
		LIMIT 1
	`
	err := r.db.GetContext(ctx, &subscription, query, merchantID)
	if err != nil {
		return nil, err
	}

	// Load plan separately
	plan, err := r.GetPlanByID(ctx, subscription.PlanID)
	if err != nil {
		return nil, err
	}
	subscription.Plan = plan

	return &subscription, nil
}

func (r *Repository) GetPlanByID(ctx context.Context, planID uuid.UUID) (*domain.Plan, error) {
	var plan domain.Plan
	query := `SELECT * FROM plans WHERE id = $1`
	err := r.db.GetContext(ctx, &plan, query, planID)
	if err != nil {
		return nil, err
	}
	return &plan, nil
}

func (r *Repository) CreateSubscription(ctx context.Context, sub *domain.Subscription) error {
	query := `
		INSERT INTO subscriptions (id, merchant_id, plan_id, status, started_at, current_period_start, current_period_end, created_at, updated_at)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
	`
	_, err := r.db.ExecContext(ctx, query,
		sub.ID, sub.MerchantID, sub.PlanID, sub.Status,
		sub.StartedAt, sub.CurrentPeriodStart, sub.CurrentPeriodEnd,
		sub.CreatedAt, sub.UpdatedAt,
	)
	return err
}

func (r *Repository) UpdateSubscription(ctx context.Context, sub *domain.Subscription) error {
	query := `
		UPDATE subscriptions
		SET plan_id = $1, status = $2, current_period_start = $3, current_period_end = $4,
		    canceled_at = $5, updated_at = $6
		WHERE id = $7
	`
	_, err := r.db.ExecContext(ctx, query,
		sub.PlanID, sub.Status, sub.CurrentPeriodStart, sub.CurrentPeriodEnd,
		sub.CanceledAt, sub.UpdatedAt, sub.ID,
	)
	return err
}

func (r *Repository) CountActiveCampaigns(ctx context.Context, merchantID uuid.UUID) (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM campaigns WHERE merchant_id = $1 AND is_active = TRUE`
	err := r.db.GetContext(ctx, &count, query, merchantID)
	return count, err
}
