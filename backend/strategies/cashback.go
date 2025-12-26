package strategies

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/Ananiaslitz/fidelio/domain"
)

// CashbackStrategy implements percentage-based cashback rewards
type CashbackStrategy struct{}

// NewCashbackStrategy creates a new cashback strategy instance
func NewCashbackStrategy() *CashbackStrategy {
	return &CashbackStrategy{}
}

// GetType returns the campaign type
func (s *CashbackStrategy) GetType() domain.CampaignType {
	return domain.CampaignTypeCashback
}

// Validate ensures the cashback configuration is valid
func (s *CashbackStrategy) Validate(config json.RawMessage) error {
	var cfg domain.CashbackConfig
	if err := json.Unmarshal(config, &cfg); err != nil {
		return fmt.Errorf("invalid cashback config: %w", err)
	}

	if cfg.Percentage <= 0 || cfg.Percentage > 100 {
		return fmt.Errorf("percentage must be between 0 and 100")
	}

	if cfg.MaxCashback < 0 {
		return fmt.Errorf("max_cashback cannot be negative")
	}

	return nil
}

// Execute processes a transaction and calculates cashback
func (s *CashbackStrategy) Execute(ctx context.Context, input *domain.StrategyInput) (*domain.StrategyResult, error) {
	// Parse configuration
	var config domain.CashbackConfig
	if err := json.Unmarshal(input.Campaign.Config, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	// Check minimum purchase requirement
	if config.MinPurchase > 0 && input.Amount < config.MinPurchase {
		return &domain.StrategyResult{
			NewBalance:   0,
			NewState:     input.CurrentState,
			StateChanged: false,
		}, nil
	}

	// Parse current state
	var state domain.CashbackState
	if len(input.CurrentState) > 0 {
		if err := json.Unmarshal(input.CurrentState, &state); err != nil {
			state = domain.CashbackState{
				TotalEarned:   0,
				TotalRedeemed: 0,
			}
		}
	}

	// Calculate cashback
	cashbackAmount := input.Amount * (config.Percentage / 100.0)

	// Apply max cashback cap if configured
	if config.MaxCashback > 0 && cashbackAmount > config.MaxCashback {
		cashbackAmount = config.MaxCashback
	}

	// Update state
	state.TotalEarned += cashbackAmount

	// Serialize new state
	newState, err := json.Marshal(state)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal state: %w", err)
	}

	reward := &domain.RewardInfo{
		Type:        "cashback",
		Amount:      cashbackAmount,
		Description: fmt.Sprintf("%.1f%% de cashback em R$ %.2f", config.Percentage, input.Amount),
	}

	return &domain.StrategyResult{
		NewBalance:   cashbackAmount,
		NewState:     newState,
		RewardEarned: reward,
		StateChanged: true,
	}, nil
}
