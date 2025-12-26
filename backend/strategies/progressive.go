package strategies

import (
	"context"
	"encoding/json"
	"fmt"
	"sort"

	"github.com/Ananiaslitz/fidelio/domain"
)

// ProgressiveStrategy implements tier-based progressive rewards
type ProgressiveStrategy struct{}

// NewProgressiveStrategy creates a new progressive strategy instance
func NewProgressiveStrategy() *ProgressiveStrategy {
	return &ProgressiveStrategy{}
}

// GetType returns the campaign type
func (s *ProgressiveStrategy) GetType() domain.CampaignType {
	return domain.CampaignTypeProgressive
}

// Validate ensures the progressive configuration is valid
func (s *ProgressiveStrategy) Validate(config json.RawMessage) error {
	var cfg domain.ProgressiveConfig
	if err := json.Unmarshal(config, &cfg); err != nil {
		return fmt.Errorf("invalid progressive config: %w", err)
	}

	if len(cfg.Tiers) == 0 {
		return fmt.Errorf("at least one tier is required")
	}

	if cfg.BasePointsRatio <= 0 {
		return fmt.Errorf("base_points_ratio must be greater than 0")
	}

	// Validate tiers are sorted by min_transactions
	for i := 1; i < len(cfg.Tiers); i++ {
		if cfg.Tiers[i].MinTransactions <= cfg.Tiers[i-1].MinTransactions {
			return fmt.Errorf("tiers must be sorted by min_transactions in ascending order")
		}
	}

	return nil
}

// Execute processes a transaction and updates tier progression
func (s *ProgressiveStrategy) Execute(ctx context.Context, input *domain.StrategyInput) (*domain.StrategyResult, error) {
	// Parse configuration
	var config domain.ProgressiveConfig
	if err := json.Unmarshal(input.Campaign.Config, &config); err != nil {
		return nil, fmt.Errorf("failed to parse config: %w", err)
	}

	// Parse current state
	var state domain.ProgressiveState
	if len(input.CurrentState) > 0 {
		if err := json.Unmarshal(input.CurrentState, &state); err != nil {
			state = domain.ProgressiveState{
				TransactionCount: 0,
				CurrentTier:      0,
				TotalPoints:      0,
			}
		}
	}

	// Increment transaction count
	state.TransactionCount++

	// Determine current tier based on transaction count
	previousTier := state.CurrentTier
	state.CurrentTier = s.calculateTier(config.Tiers, state.TransactionCount)

	// Get tier multiplier
	var tierMultiplier float64 = 1.0
	var bonusPoints float64 = 0

	if state.CurrentTier < len(config.Tiers) {
		tierMultiplier = config.Tiers[state.CurrentTier].RewardMultiplier
		// Award bonus points on tier upgrade
		if state.CurrentTier > previousTier {
			bonusPoints = config.Tiers[state.CurrentTier].BonusPoints
		}
	}

	// Calculate points earned
	basePoints := input.Amount * config.BasePointsRatio
	pointsEarned := (basePoints * tierMultiplier) + bonusPoints
	state.TotalPoints += pointsEarned

	// Serialize new state
	newState, err := json.Marshal(state)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal state: %w", err)
	}

	tierName := "Bronze"
	if state.CurrentTier < len(config.Tiers) {
		tierName = config.Tiers[state.CurrentTier].Name
	}

	description := fmt.Sprintf("Ganhou %.0f pontos no tier %s", pointsEarned, tierName)
	if bonusPoints > 0 {
		description += fmt.Sprintf(" (Bônus de %.0f pontos por atingir novo tier!)", bonusPoints)
	}

	reward := &domain.RewardInfo{
		Type:        "points",
		Amount:      pointsEarned,
		Description: description,
	}

	return &domain.StrategyResult{
		NewBalance:   pointsEarned,
		NewState:     newState,
		RewardEarned: reward,
		StateChanged: true,
	}, nil
}

// calculateTier determines the appropriate tier based on transaction count
func (s *ProgressiveStrategy) calculateTier(tiers []domain.ProgressiveTier, transactionCount int) int {
	// Sort tiers by min_transactions descending to find the highest applicable tier
	tierIndex := 0
	for i, tier := range tiers {
		if transactionCount >= tier.MinTransactions {
			tierIndex = i
		}
	}
	return tierIndex
}

// Helper function to ensure tiers are sorted
func sortTiers(tiers []domain.ProgressiveTier) {
	sort.Slice(tiers, func(i, j int) bool {
		return tiers[i].MinTransactions < tiers[j].MinTransactions
	})
}
