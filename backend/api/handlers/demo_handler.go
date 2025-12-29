package handlers

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
)

type DemoRequest struct {
	Name          string `json:"name" binding:"required"`
	Company       string `json:"company" binding:"required"`
	Email         string `json:"email" binding:"required,email"`
	Phone         string `json:"phone" binding:"required"`
	PreferredDate string `json:"preferredDate"`
}

type ResendEmailRequest struct {
	From    string   `json:"from"`
	To      []string `json:"to"`
	Subject string   `json:"subject"`
	HTML    string   `json:"html"`
}

// HandleDemoRequest handles demo scheduling requests and sends email via Resend
func HandleDemoRequest(c *gin.Context) {
	var req DemoRequest

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// Send email via Resend API
	if err := sendDemoEmail(req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send email"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Demo request received successfully"})
}

func sendDemoEmail(demo DemoRequest) error {
	resendAPIKey := os.Getenv("RESEND_API_KEY")
	if resendAPIKey == "" {
		return fmt.Errorf("RESEND_API_KEY not configured")
	}

	// Build email HTML
	emailHTML := fmt.Sprintf(`
		<h2>Nova Solicitação de Demonstração - Backly</h2>
		<p><strong>Nome:</strong> %s</p>
		<p><strong>Empresa:</strong> %s</p>
		<p><strong>Email:</strong> %s</p>
		<p><strong>Telefone:</strong> %s</p>
		<p><strong>Horário Preferido:</strong> %s</p>
		<hr>
		<p><em>Enviado automaticamente pelo formulário de demonstração do site Backly.</em></p>
	`, demo.Name, demo.Company, demo.Email, demo.Phone, demo.PreferredDate)

	emailReq := ResendEmailRequest{
		From:    "Backly Demo <onboarding@resend.dev>", // Change to your verified domain
		To:      []string{"contato@fidelio.com.br"},
		Subject: fmt.Sprintf("Nova Demo: %s - %s", demo.Company, demo.Name),
		HTML:    emailHTML,
	}

	jsonData, err := json.Marshal(emailReq)
	if err != nil {
		return err
	}

	req, err := http.NewRequest("POST", "https://api.resend.com/emails", bytes.NewBuffer(jsonData))
	if err != nil {
		return err
	}

	req.Header.Set("Authorization", "Bearer "+resendAPIKey)
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("resend API returned status %d", resp.StatusCode)
	}

	return nil
}
