package strategies

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/Ananiaslitz/fidelio/domain"
)

// PunchCardStrategy implements the "Buy X, Get Y" punch card logic
type PunchCardStrategy struct{}

// NewPunchCardStrategy creates a new punch card strategy instance
func NewPunchCardStrategy() *PunchCardStrategy {
	return &PunchCardStrategy{}
}

// GetType returns the campaign type
func (s *PunchCardStrategy) GetType() domain.CampaignType {
	return domain.CampaignTypePunchCard
}

// Validate ensures the punch card configuration is valid
func (s *PunchCardStrategy) Validate(config json.RawMessage) error {
	var cfg domain.PunchCardConfig
	if err := json.Unmarshal(config, &cfg); err != nil {
		return fmt.Errorf("invalid punch card config: %w", err)
	}

	if cfg.RequiredPunches <= 0 {
		return fmt.Errorf("required_punches must be greater than 0")
	}

	if cfg.RewardAmount <= 0 {
		return fmt.Errorf("reward_amount must be greater than 0")
	}

	validRewardTypes := map[string]bool{
		"points":    true,
		"discount":  true,
		"free_item": true,
	}

	if !validRewardTypes[cfg.RewardType] {
		return fmt.Errorf("invalid reward_type: %s", cfg.RewardType)
	}

	return nil
}

// Execute processes a transaction and updates the punch card state
func (s *PunchCardStrategy) Execute(ctx context.Context, input *domain.StrategyInput) (*domain.StrategyResult, error) {
	// Parse configuration
	var config domain.PunchCardConfig
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
	var state domain.PunchCardState
	if len(input.CurrentState) > 0 {
		if err := json.Unmarshal(input.CurrentState, &state); err != nil {
			// Initialize new state if parsing fails
			state = domain.PunchCardState{
				CurrentPunches: 0,
				TotalRedeemed:  0,
			}
		}
	}

	// Increment punch count
	state.CurrentPunches++

	var reward *domain.RewardInfo
	newBalance := 0.0

	// Check if reward earned
	if state.CurrentPunches >= config.RequiredPunches {
		// Award the reward
		newBalance = config.RewardAmount
		state.CurrentPunches = 0 // Reset punches
		state.TotalRedeemed++

		reward = &domain.RewardInfo{
			Type:        config.RewardType,
			Amount:      config.RewardAmount,
			Description: fmt.Sprintf("Completou %d compras! Parabéns!", config.RequiredPunches),
		}
	}

	// Serialize new state
	newState, err := json.Marshal(state)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal state: %w", err)
	}

	return &domain.StrategyResult{
		NewBalance:   newBalance,
		NewState:     newState,
		RewardEarned: reward,
		StateChanged: true,
	}, nil
}
