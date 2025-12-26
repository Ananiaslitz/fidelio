package domain

import (
	"context"
	"encoding/json"
)

// CampaignStrategy defines the interface for all campaign types
// This is the core of the Strategy Pattern implementation
type CampaignStrategy interface {
	// Execute processes a transaction and returns the result
	Execute(ctx context.Context, input *StrategyInput) (*StrategyResult, error)

	// Validate ensures the campaign configuration is valid
	Validate(config json.RawMessage) error

	// GetType returns the campaign type this strategy handles
	GetType() CampaignType
}

// StrategyInput contains all data needed to execute a campaign strategy
type StrategyInput struct {
	Campaign      *Campaign
	TransactionID string
	Amount        float64
	CurrentState  json.RawMessage // Current wallet/shadow state
	Metadata      json.RawMessage
}

// StrategyResult contains the outcome of strategy execution
type StrategyResult struct {
	NewBalance   float64
	NewState     json.RawMessage
	RewardEarned *RewardInfo
	StateChanged bool
}

// PunchCardConfig defines the configuration for punch card campaigns
type PunchCardConfig struct {
	RequiredPunches int     `json:"required_punches"`
	RewardAmount    float64 `json:"reward_amount"`
	RewardType      string  `json:"reward_type"` // "points", "discount", "free_item"
	MinPurchase     float64 `json:"min_purchase,omitempty"`
}

// PunchCardState tracks the current state of a punch card
type PunchCardState struct {
	CurrentPunches int `json:"current_punches"`
	TotalRedeemed  int `json:"total_redeemed"`
}

// CashbackConfig defines the configuration for cashback campaigns
type CashbackConfig struct {
	Percentage  float64 `json:"percentage"`
	MaxCashback float64 `json:"max_cashback,omitempty"`
	MinPurchase float64 `json:"min_purchase,omitempty"`
}

// CashbackState tracks the cumulative cashback
type CashbackState struct {
	TotalEarned   float64 `json:"total_earned"`
	TotalRedeemed float64 `json:"total_redeemed"`
}

// ProgressiveTier represents a tier in a progressive campaign
type ProgressiveTier struct {
	Name             string  `json:"name"`
	MinTransactions  int     `json:"min_transactions"`
	RewardMultiplier float64 `json:"reward_multiplier"`
	BonusPoints      float64 `json:"bonus_points,omitempty"`
}

// ProgressiveConfig defines the configuration for progressive campaigns
type ProgressiveConfig struct {
	Tiers           []ProgressiveTier `json:"tiers"`
	BasePointsRatio float64           `json:"base_points_ratio"` // Points per $ spent
}

// ProgressiveState tracks the current tier and transaction count
type ProgressiveState struct {
	TransactionCount int     `json:"transaction_count"`
	CurrentTier      int     `json:"current_tier"`
	TotalPoints      float64 `json:"total_points"`
}
