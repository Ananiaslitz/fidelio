package handlers

import (
	"net/http"

	"github.com/Ananiaslitz/fidelio/domain"
	"github.com/Ananiaslitz/fidelio/repository"
	"github.com/Ananiaslitz/fidelio/services"

	"github.com/gin-gonic/gin"
)

// IngestHandler handles the /v1/ingest endpoint
type IngestHandler struct {
	engine *services.IngestionEngine
	repo   *repository.Repository
}

// NewIngestHandler creates a new ingest handler
func NewIngestHandler(engine *services.IngestionEngine, repo *repository.Repository) *IngestHandler {
	return &IngestHandler{
		engine: engine,
		repo:   repo,
	}
}

// Handle processes the ingest request
// POST /v1/ingest
func (h *IngestHandler) Handle(c *gin.Context) {
	// Get merchant from context (set by auth middleware)
	merchant, exists := c.Get("merchant")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "merchant not found in context",
		})
		return
	}

	merchantObj, ok := merchant.(*domain.Merchant)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "invalid merchant object",
		})
		return
	}

	// Parse request body
	var req domain.IngestRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"error":   "invalid request body",
			"details": err.Error(),
		})
		return
	}

	// Validate request
	if req.Amount <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "amount must be greater than 0",
		})
		return
	}

	// Process transaction
	response, err := h.engine.ProcessTransaction(c.Request.Context(), merchantObj, &req)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error":   "failed to process transaction",
			"details": err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, response)
}

// AuthMiddleware validates the API key and loads the merchant
func AuthMiddleware(repo *repository.Repository) gin.HandlerFunc {
	return func(c *gin.Context) {
		apiKey := c.GetHeader("X-API-Key")
		if apiKey == "" {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "API key required",
			})
			c.Abort()
			return
		}

		// Get merchant by API key
		merchant, err := repo.GetMerchantByAPIKey(c.Request.Context(), apiKey)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{
				"error": "invalid API key",
			})
			c.Abort()
			return
		}

		// Store merchant in context
		c.Set("merchant", merchant)
		c.Next()
	}
}

// HealthHandler returns the health status of the service
func HealthHandler(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "healthy",
		"service": "fidelio-loyalty-api",
		"version": "1.0.0",
	})
}

// StatsHandler returns merchant statistics
type StatsHandler struct {
	repo              *repository.Repository
	conversionService *services.ConversionService
}

// NewStatsHandler creates a new stats handler
func NewStatsHandler(repo *repository.Repository, convService *services.ConversionService) *StatsHandler {
	return &StatsHandler{
		repo:              repo,
		conversionService: convService,
	}
}

// Handle returns merchant statistics
// GET /v1/stats
func (h *StatsHandler) Handle(c *gin.Context) {
	merchant, exists := c.Get("merchant")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{
			"error": "merchant not found",
		})
		return
	}

	merchantObj := merchant.(*domain.Merchant)

	// Get conversion stats
	stats, err := h.conversionService.GetConversionStats(c.Request.Context(), merchantObj.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"error": "failed to get stats",
		})
		return
	}

	c.JSON(http.StatusOK, stats)
}
