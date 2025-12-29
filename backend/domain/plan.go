package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// Plan represents a subscription plan
type Plan struct {
	ID           uuid.UUID       `json:"id" db:"id"`
	Slug         string          `json:"slug" db:"slug"`
	Name         string          `json:"name" db:"name"`
	Description  *string         `json:"description,omitempty" db:"description"`
	PriceMonthly float64         `json:"priceMonthly" db:"price_monthly"`
	Currency     string          `json:"currency" db:"currency"`
	IsPopular    bool            `json:"isPopular" db:"is_popular"`
	IsActive     bool            `json:"isActive" db:"is_active"`
	Features     json.RawMessage `json:"features" db:"features"`
	Limits       json.RawMessage `json:"limits" db:"limits"`
	CreatedAt    time.Time       `json:"createdAt" db:"created_at"`
	UpdatedAt    time.Time       `json:"updatedAt" db:"updated_at"`
}

// PlanLimits represents the limits for a plan
type PlanLimits struct {
	MaxActiveCampaigns int `json:"maxActiveCampaigns"`
	MaxCustomers       int `json:"maxCustomers"`
}

// GetLimits parses the limits JSON into a PlanLimits struct
func (p *Plan) GetLimits() (*PlanLimits, error) {
	var limits PlanLimits
	if err := json.Unmarshal(p.Limits, &limits); err != nil {
		return nil, err
	}
	return &limits, nil
}

// Subscription represents a merchant's subscription to a plan
type Subscription struct {
	ID                 uuid.UUID  `json:"id" db:"id"`
	MerchantID         uuid.UUID  `json:"merchantId" db:"merchant_id"`
	PlanID             uuid.UUID  `json:"planId" db:"plan_id"`
	Status             string     `json:"status" db:"status"`
	StartedAt          time.Time  `json:"startedAt" db:"started_at"`
	CurrentPeriodStart time.Time  `json:"currentPeriodStart" db:"current_period_start"`
	CurrentPeriodEnd   time.Time  `json:"currentPeriodEnd" db:"current_period_end"`
	CanceledAt         *time.Time `json:"canceledAt,omitempty" db:"canceled_at"`
	CreatedAt          time.Time  `json:"createdAt" db:"created_at"`
	UpdatedAt          time.Time  `json:"updatedAt" db:"updated_at"`

	// Joined fields
	Plan *Plan `json:"plan,omitempty" db:"-"`
}
