package handlers

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"io"
	"net/http"

	"github.com/Ananiaslitz/fidelio/services"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// WebhookHandler handles Supabase auth webhooks
type WebhookHandler struct {
	conversionService *services.ConversionService
	webhookSecret     string
}

// NewWebhookHandler creates a new webhook handler
func NewWebhookHandler(convService *services.ConversionService, secret string) *WebhookHandler {
	return &WebhookHandler{
		conversionService: convService,
		webhookSecret:     secret,
	}
}

// SupabaseWebhookPayload represents the webhook payload from Supabase
type SupabaseWebhookPayload struct {
	Type   string                 `json:"type"`
	Table  string                 `json:"table"`
	Record map[string]interface{} `json:"record"`
	Schema string                 `json:"schema"`
}

// HandleUserCreated processes user creation webhooks from Supabase
// POST /v1/webhook/user-created
func (h *WebhookHandler) HandleUserCreated(c *gin.Context) {
	// Verify webhook signature
	signature := c.GetHeader("X-Webhook-Signature")
	if !h.verifySignature(c, signature) {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "invalid webhook signature",
		})
		return
	}

	// Parse webhook payload
	var payload SupabaseWebhookPayload
	if err := c.ShouldBindJSON(&payload); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid payload",
		})
		return
	}

	// Validate payload type
	if payload.Type != "INSERT" || payload.Table != "users" {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "unexpected webhook type",
		})
		return
	}

	// Extract user data
	userID, ok := payload.Record["id"].(string)
	if !ok {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "missing user id",
		})
		return
	}

	phone, ok := payload.Record["phone"].(string)
	if !ok || phone == "" {
		// No phone number, nothing to convert
		c.JSON(http.StatusOK, gin.H{
			"message": "user has no phone number",
		})
		return
	}

	// Parse user UUID
	parsedUserID, err := uuid.Parse(userID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "invalid user id format",
		})
		return
	}

	// Hash the phone number (same as ingestion)
	phoneHash := h.hashPhone(phone)

	// Call conversion service
	if err := h.conversionService.ConvertShadowToRealWallet(c.Request.Context(), parsedUserID, phoneHash); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "conversion failed",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "shadow wallet converted successfully",
		"user_id": userID,
	})
}

// verifySignature validates the webhook signature from Supabase
func (h *WebhookHandler) verifySignature(c *gin.Context, signature string) bool {
	if h.webhookSecret == "" {
		// If no secret is configured, skip verification (NOT RECOMMENDED FOR PRODUCTION)
		return true
	}

	// Read request body
	body, err := c.GetRawData()
	if err != nil {
		return false
	}

	// Restore body for further processing
	c.Request.Body = io.NopCloser(bytes.NewBuffer(body))

	// Calculate HMAC
	mac := hmac.New(sha256.New, []byte(h.webhookSecret))
	mac.Write(body)
	expectedSignature := hex.EncodeToString(mac.Sum(nil))

	// Compare signatures
	return hmac.Equal([]byte(signature), []byte(expectedSignature))
}

// hashPhone creates a SHA-256 hash of the phone number
func (h *WebhookHandler) hashPhone(phone string) string {
	hash := sha256.Sum256([]byte(phone))
	return hex.EncodeToString(hash[:])
}
