package handlers

import (
	"net/http"

	"github.com/Ananiaslitz/fidelio/repository"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type PlansHandler struct {
	repo *repository.Repository
}

func NewPlansHandler(repo *repository.Repository) *PlansHandler {
	return &PlansHandler{repo: repo}
}

// HandleGetPlans returns all active plans
func (h *PlansHandler) HandleGetPlans(c *gin.Context) {
	plans, err := h.repo.GetAllActivePlans(c.Request.Context())
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch plans"})
		return
	}

	c.JSON(http.StatusOK, plans)
}

// HandleGetSubscription returns the current merchant's subscription
func (h *PlansHandler) HandleGetSubscription(c *gin.Context) {
	merchantID, exists := c.Get("merchant_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Merchant ID not found"})
		return
	}

	subscription, err := h.repo.GetMerchantSubscription(c.Request.Context(), merchantID.(uuid.UUID))
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No active subscription found"})
		return
	}

	c.JSON(http.StatusOK, subscription)
}
