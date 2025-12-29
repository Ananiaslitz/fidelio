package services

import (
	"context"

	"github.com/google/uuid"
)

// MockSupabaseAuth implements a mock authentication client for testing
type MockSupabaseAuth struct {
}

// NewMockSupabaseAuthClient creates a new mock Supabase auth client
func NewMockSupabaseAuthClient() *MockSupabaseAuth {
	return &MockSupabaseAuth{}
}

// UserExistsByPhone always returns false for testing shadow wallet flows
func (c *MockSupabaseAuth) UserExistsByPhone(ctx context.Context, phone string) (*uuid.UUID, bool, error) {
	// For testing purposes, we assume the user does not exist
	// This allows the shadow wallet flow to proceed
	return nil, false, nil
}
