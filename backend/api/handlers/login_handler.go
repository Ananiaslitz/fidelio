package handlers

import (
	"log"
	"net/http"

	"github.com/Ananiaslitz/fidelio/repository"
	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

type LoginHandler struct {
	repo *repository.Repository
}

func NewLoginHandler(repo *repository.Repository) *LoginHandler {
	return &LoginHandler{repo: repo}
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type LoginResponse struct {
	Success  bool   `json:"success"`
	APIKey   string `json:"apiKey,omitempty"`
	Merchant struct {
		ID    string `json:"id"`
		Name  string `json:"name"`
		Email string `json:"email"`
	} `json:"merchant,omitempty"`
	Message string `json:"message,omitempty"`
}

// HandleLogin authenticates a merchant and returns their API key
func (h *LoginHandler) HandleLogin(c *gin.Context) {
	var req LoginRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, LoginResponse{
			Success: false,
			Message: "Invalid request format",
		})
		return
	}

	// Debug logging
	log.Println("=== LOGIN ATTEMPT ===")
	log.Println("Email:", req.Email)
	log.Println("Password length:", len(req.Password))

	// TEMPORARY: Mock login for testing (remove this later!)
	if req.Email == "admin@fidelio.com" || req.Email == "demo@fidelio.com" {
		log.Println("🔧 MOCK LOGIN: Bypassing database, returning mock merchant")
		c.JSON(http.StatusOK, LoginResponse{
			Success: true,
			APIKey:  "demo-merchant-key-12345",
			Merchant: struct {
				ID    string `json:"id"`
				Name  string `json:"name"`
				Email string `json:"email"`
			}{
				ID:    "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
				Name:  "Loja Demo Backly",
				Email: req.Email,
			},
		})
		return
	}

	// Get merchant by email
	merchant, err := h.repo.GetMerchantByEmail(c.Request.Context(), req.Email)
	if err != nil {
		log.Println("ERROR: Failed to find merchant:", err.Error())
		c.JSON(http.StatusUnauthorized, LoginResponse{
			Success: false,
			Message: "Invalid email or password",
		})
		return
	}

	log.Println("SUCCESS: Found merchant:", merchant.Name, "| API Key:", merchant.APIKey)

	// Verify password (if password is stored)
	// For now, we'll skip password verification since merchants table doesn't have password field
	// In production, you should add a password_hash column and verify it here

	// Return success with API key
	c.JSON(http.StatusOK, LoginResponse{
		Success: true,
		APIKey:  merchant.APIKey,
		Merchant: struct {
			ID    string `json:"id"`
			Name  string `json:"name"`
			Email string `json:"email"`
		}{
			ID:    merchant.ID.String(),
			Name:  merchant.Name,
			Email: req.Email,
		},
	})
}

// Helper function to hash passwords (for future use)
func hashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

// Helper function to check password hash (for future use)
func checkPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}
