package handlers

import (
	"net/http"
	"time"

	"github.com/Ananiaslitz/fidelio/domain"
	"github.com/Ananiaslitz/fidelio/repository"
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type CampaignHandler struct {
	repo *repository.Repository
}

func NewCampaignHandler(repo *repository.Repository) *CampaignHandler {
	return &CampaignHandler{repo: repo}
}

type CreateCampaignRequest struct {
	Name        string `json:"name" binding:"required"`
	Description string `json:"description"`
	Type        string `json:"type" binding:"required"`
	Config      string `json:"config" binding:"required"`
	StartsAt    string `json:"startsAt"`
	EndsAt      string `json:"endsAt"`
}

// HandleCreateCampaign creates a new campaign
func (h *CampaignHandler) HandleCreateCampaign(c *gin.Context) {
	var req CreateCampaignRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Get merchant ID from context (set by auth middleware)
	merchantID, exists := c.Get("merchant_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Merchant ID not found"})
		return
	}

	// Get merchant subscription to check limits
	subscription, err := h.repo.GetMerchantSubscription(c.Request.Context(), merchantID.(uuid.UUID))
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{
			"error":   "No active subscription found",
			"message": "Please subscribe to a plan to create campaigns",
		})
		return
	}

	// Get plan limits
	limits, err := subscription.Plan.GetLimits()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to load plan limits"})
		return
	}

	// Check campaign limit (if not unlimited)
	if limits.MaxActiveCampaigns > 0 {
		count, err := h.repo.CountActiveCampaigns(c.Request.Context(), merchantID.(uuid.UUID))
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to check campaign limit"})
			return
		}

		if count >= limits.MaxActiveCampaigns {
			c.JSON(http.StatusForbidden, gin.H{
				"error":       "Campaign limit reached",
				"message":     "You have reached the maximum number of active campaigns for your plan. Upgrade to create more campaigns.",
				"currentPlan": subscription.Plan.Name,
				"limit":       limits.MaxActiveCampaigns,
			})
			return
		}
	}

	// Parse dates
	var startsAt, endsAt *time.Time
	if req.StartsAt != "" {
		t, err := time.Parse("2006-01-02", req.StartsAt)
		if err == nil {
			startsAt = &t
		}
	}
	if req.EndsAt != "" {
		t, err := time.Parse("2006-01-02", req.EndsAt)
		if err == nil {
			endsAt = &t
		}
	}

	campaign := &domain.Campaign{
		ID:         uuid.New(),
		MerchantID: merchantID.(uuid.UUID),
		Name:       req.Name,
		Type:       domain.CampaignType(req.Type),
		Config:     []byte(req.Config),
		IsActive:   true,
		StartsAt:   startsAt,
		EndsAt:     endsAt,
		CreatedAt:  time.Now(),
		UpdatedAt:  time.Now(),
	}

	if err := h.repo.CreateCampaign(c.Request.Context(), campaign); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create campaign"})
		return
	}

	c.JSON(http.StatusCreated, campaign)
}

// HandleListCampaigns lists all campaigns for a merchant
func (h *CampaignHandler) HandleListCampaigns(c *gin.Context) {
	merchantID, exists := c.Get("merchant_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Merchant ID not found"})
		return
	}

	campaigns, err := h.repo.GetCampaignsByMerchant(c.Request.Context(), merchantID.(uuid.UUID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch campaigns"})
		return
	}

	c.JSON(http.StatusOK, campaigns)
}

// HandleGetCampaign gets a single campaign by ID
func (h *CampaignHandler) HandleGetCampaign(c *gin.Context) {
	campaignID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid campaign ID"})
		return
	}

	campaign, err := h.repo.GetCampaignByID(c.Request.Context(), campaignID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Campaign not found"})
		return
	}

	c.JSON(http.StatusOK, campaign)
}

// HandleUpdateCampaign updates a campaign
func (h *CampaignHandler) HandleUpdateCampaign(c *gin.Context) {
	campaignID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid campaign ID"})
		return
	}

	var req CreateCampaignRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	campaign, err := h.repo.GetCampaignByID(c.Request.Context(), campaignID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Campaign not found"})
		return
	}

	// Update fields
	campaign.Name = req.Name
	campaign.Type = domain.CampaignType(req.Type)
	campaign.Config = []byte(req.Config)
	campaign.UpdatedAt = time.Now()

	if req.StartsAt != "" {
		t, err := time.Parse("2006-01-02", req.StartsAt)
		if err == nil {
			campaign.StartsAt = &t
		}
	}
	if req.EndsAt != "" {
		t, err := time.Parse("2006-01-02", req.EndsAt)
		if err == nil {
			campaign.EndsAt = &t
		}
	}

	if err := h.repo.UpdateCampaign(c.Request.Context(), campaign); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update campaign"})
		return
	}

	c.JSON(http.StatusOK, campaign)
}

// HandleDeleteCampaign deletes a campaign
func (h *CampaignHandler) HandleDeleteCampaign(c *gin.Context) {
	campaignID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid campaign ID"})
		return
	}

	if err := h.repo.DeleteCampaign(c.Request.Context(), campaignID); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete campaign"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Campaign deleted successfully"})
}

// HandleToggleCampaign toggles campaign active status
func (h *CampaignHandler) HandleToggleCampaign(c *gin.Context) {
	campaignID, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid campaign ID"})
		return
	}

	campaign, err := h.repo.GetCampaignByID(c.Request.Context(), campaignID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Campaign not found"})
		return
	}

	campaign.IsActive = !campaign.IsActive
	campaign.UpdatedAt = time.Now()

	if err := h.repo.UpdateCampaign(c.Request.Context(), campaign); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to toggle campaign"})
		return
	}

	c.JSON(http.StatusOK, campaign)
}
