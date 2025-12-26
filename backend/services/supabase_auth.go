package services

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/google/uuid"
)

// SupabaseAuth implements the authentication client for Supabase
type SupabaseAuth struct {
	baseURL    string
	serviceKey string
	client     *http.Client
}

// NewSupabaseAuthClient creates a new Supabase auth client
func NewSupabaseAuthClient(baseURL, serviceKey string) *SupabaseAuth {
	return &SupabaseAuth{
		baseURL:    baseURL,
		serviceKey: serviceKey,
		client:     &http.Client{},
	}
}

// UserExistsByPhone checks if a user exists with the given phone number
func (c *SupabaseAuth) UserExistsByPhone(ctx context.Context, phone string) (*uuid.UUID, bool, error) {
	// Construct the Supabase Admin API endpoint
	url := fmt.Sprintf("%s/auth/v1/admin/users", c.baseURL)

	// Create request with phone filter
	req, err := http.NewRequestWithContext(ctx, "GET", url, nil)
	if err != nil {
		return nil, false, fmt.Errorf("failed to create request: %w", err)
	}

	// Add query parameters to filter by phone
	q := req.URL.Query()
	q.Add("phone", "eq."+phone)
	req.URL.RawQuery = q.Encode()

	// Add authorization header
	req.Header.Set("apikey", c.serviceKey)
	req.Header.Set("Authorization", "Bearer "+c.serviceKey)

	// Execute request
	resp, err := c.client.Do(req)
	if err != nil {
		return nil, false, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, false, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	// Parse response
	var users []struct {
		ID    string `json:"id"`
		Phone string `json:"phone"`
	}

	if err := json.NewDecoder(resp.Body).Decode(&users); err != nil {
		return nil, false, fmt.Errorf("failed to decode response: %w", err)
	}

	// Check if user exists
	if len(users) == 0 {
		return nil, false, nil
	}

	// Parse user ID
	userID, err := uuid.Parse(users[0].ID)
	if err != nil {
		return nil, false, fmt.Errorf("invalid user ID: %w", err)
	}

	return &userID, true, nil
}
