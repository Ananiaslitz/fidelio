package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// CampaignType represents the type of loyalty campaign
type CampaignType string

const (
	CampaignTypePunchCard   CampaignType = "PUNCH_CARD"
	CampaignTypeCashback    CampaignType = "CASHBACK"
	CampaignTypeProgressive CampaignType = "PROGRESSIVE"
)

// TransactionType represents the type of loyalty transaction
type TransactionType string

const (
	TransactionTypeEarn    TransactionType = "EARN"
	TransactionTypeRedeem  TransactionType = "REDEEM"
	TransactionTypeExpire  TransactionType = "EXPIRE"
	TransactionTypeConvert TransactionType = "CONVERT"
)

// Merchant represents a business using the loyalty platform
type Merchant struct {
	ID         uuid.UUID       `json:"id" db:"id"`
	Name       string          `json:"name" db:"name"`
	APIKey     string          `json:"api_key" db:"api_key"`
	Settings   json.RawMessage `json:"settings" db:"settings"`
	Latitude   *float64        `json:"latitude,omitempty" db:"latitude"`
	Longitude  *float64        `json:"longitude,omitempty" db:"longitude"`
	Address    *string         `json:"address,omitempty" db:"address"`
	LogoURL    *string         `json:"logo_url,omitempty" db:"logo_url"`
	BannerURL  *string         `json:"banner_url,omitempty" db:"banner_url"`
	Category   *string         `json:"category,omitempty" db:"category"`
	CategoryID *uuid.UUID      `json:"category_id,omitempty" db:"category_id"`
	CreatedAt  time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time       `json:"updated_at" db:"updated_at"`
}

// Campaign represents a loyalty campaign
type Campaign struct {
	ID         uuid.UUID       `json:"id" db:"id"`
	MerchantID uuid.UUID       `json:"merchant_id" db:"merchant_id"`
	Name       string          `json:"name" db:"name"`
	Type       CampaignType    `json:"type" db:"type"`
	Config     json.RawMessage `json:"config" db:"config"`
	IsActive   bool            `json:"is_active" db:"is_active"`
	StartsAt   *time.Time      `json:"starts_at" db:"starts_at"`
	EndsAt     *time.Time      `json:"ends_at" db:"ends_at"`
	CreatedAt  time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time       `json:"updated_at" db:"updated_at"`
}

// Wallet represents a customer's loyalty balance with a merchant
type Wallet struct {
	ID         uuid.UUID       `json:"id" db:"id"`
	MerchantID uuid.UUID       `json:"merchant_id" db:"merchant_id"`
	UserID     uuid.UUID       `json:"user_id" db:"user_id"`
	PhoneHash  string          `json:"phone_hash" db:"phone_hash"`
	Balance    float64         `json:"balance" db:"balance"`
	State      json.RawMessage `json:"state" db:"state"`
	CreatedAt  time.Time       `json:"created_at" db:"created_at"`
	UpdatedAt  time.Time       `json:"updated_at" db:"updated_at"`
}

// ShadowBalance represents a temporary loyalty balance for unregistered users
type ShadowBalance struct {
	ID          uuid.UUID       `json:"id" db:"id"`
	MerchantID  uuid.UUID       `json:"merchant_id" db:"merchant_id"`
	PhoneHash   string          `json:"phone_hash" db:"phone_hash"`
	Amount      float64         `json:"amount" db:"amount"`
	State       json.RawMessage `json:"state" db:"state"`
	ExpiresAt   time.Time       `json:"expires_at" db:"expires_at"`
	CreatedAt   time.Time       `json:"created_at" db:"created_at"`
	ConvertedAt *time.Time      `json:"converted_at" db:"converted_at"`
}

// Transaction represents a loyalty transaction in the immutable ledger
type Transaction struct {
	ID              uuid.UUID       `json:"id" db:"id"`
	MerchantID      uuid.UUID       `json:"merchant_id" db:"merchant_id"`
	CampaignID      *uuid.UUID      `json:"campaign_id" db:"campaign_id"`
	WalletID        *uuid.UUID      `json:"wallet_id" db:"wallet_id"`
	ShadowBalanceID *uuid.UUID      `json:"shadow_balance_id" db:"shadow_balance_id"`
	Type            TransactionType `json:"transaction_type" db:"transaction_type"`
	Amount          float64         `json:"amount" db:"amount"`
	Metadata        json.RawMessage `json:"metadata" db:"metadata"`
	CreatedAt       time.Time       `json:"created_at" db:"created_at"`
}

// IngestRequest represents the payload for the ingestion endpoint
type IngestRequest struct {
	Phone         string          `json:"phone" binding:"required"`
	TransactionID string          `json:"transaction_id" binding:"required"`
	Amount        float64         `json:"amount" binding:"required"`
	Metadata      json.RawMessage `json:"metadata"`
}

// IngestResponse represents the response from the ingestion endpoint
type IngestResponse struct {
	Success    bool        `json:"success"`
	NewBalance float64     `json:"new_balance"`
	IsShadow   bool        `json:"is_shadow"`
	ExpiresAt  *time.Time  `json:"expires_at,omitempty"`
	Reward     *RewardInfo `json:"reward,omitempty"`
	Message    string      `json:"message,omitempty"`
}

// RewardInfo contains information about earned rewards
type RewardInfo struct {
	Type        string  `json:"type"`
	Amount      float64 `json:"amount"`
	Description string  `json:"description"`
}

// ConversionStats holds statistics about shadow wallet conversions
type ConversionStats struct {
	TotalShadowBalances  int64   `db:"total_shadow_balances" json:"total_shadow_balances"`
	ConvertedBalances    int64   `db:"converted_balances" json:"converted_balances"`
	ExpiredBalances      int64   `db:"expired_balances" json:"expired_balances"`
	ActiveShadowBalances int64   `db:"active_shadow_balances" json:"active_shadow_balances"`
	TotalConvertedAmount float64 `db:"total_converted_amount" json:"total_converted_amount"`
	TotalBreakageAmount  float64 `db:"total_breakage_amount" json:"total_breakage_amount"`
	ConversionRate       float64 `json:"conversion_rate"`
}

// ExpirationMetrics holds metrics about expired shadow balances
type ExpirationMetrics struct {
	TotalExpired    int64   `json:"total_expired"`
	TotalBreakage   float64 `json:"total_breakage"`
	AverageBreakage float64 `json:"average_breakage"`
}
