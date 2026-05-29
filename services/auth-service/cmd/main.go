// NimbusCloud Auth Service v2.4.1
// JWT token issuance and session management
// ⚠️ NOTE: DB_PASSWORD must be sourced from AWS Secrets Manager
//          The .env file in this directory has a hardcoded value — SEE SECURITY FINDING
package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequests = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "auth_service_requests_total",
			Help: "Total HTTP requests",
		},
		[]string{"method", "endpoint", "status"},
	)
	httpDuration = prometheus.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "auth_service_duration_seconds",
			Help:    "HTTP request duration",
			Buckets: []float64{0.1, 0.5, 1, 2, 5},
		},
		[]string{"endpoint"},
	)
	tokenIssued = prometheus.NewCounter(prometheus.CounterOpts{
		Name: "auth_service_tokens_issued_total",
		Help: "Total JWT tokens issued",
	})
)

func init() {
	prometheus.MustRegister(httpRequests, httpDuration, tokenIssued)
}

type TokenRequest struct {
	UserID   string `json:"user_id" binding:"required"`
	ClientID string `json:"client_id" binding:"required"`
}

type TokenResponse struct {
	Token     string `json:"token"`
	ExpiresAt int64  `json:"expires_at"`
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "3003"
	}

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		log.Fatal("JWT_SECRET not set — check Secrets Manager configuration")
	}

	gin.SetMode(gin.ReleaseMode)
	r := gin.New()
	r.Use(gin.Recovery())

	r.GET("/healthz", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "ok",
			"service":   "auth-service",
			"version":   "2.4.1",
			"timestamp": time.Now().UTC().Format(time.RFC3339),
		})
	})

	r.GET("/metrics", gin.WrapH(promhttp.Handler()))

	r.POST("/api/v1/auth/token", func(c *gin.Context) {
		timer := prometheus.NewTimer(httpDuration.WithLabelValues("/api/v1/auth/token"))
		defer timer.ObserveDuration()

		var req TokenRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			httpRequests.WithLabelValues("POST", "/api/v1/auth/token", "400").Inc()
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		expiresAt := time.Now().Add(time.Hour).Unix()
		claims := jwt.MapClaims{
			"sub":       req.UserID,
			"client_id": req.ClientID,
			"iat":       time.Now().Unix(),
			"exp":       expiresAt,
		}

		token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
		signed, err := token.SignedString([]byte(jwtSecret))
		if err != nil {
			httpRequests.WithLabelValues("POST", "/api/v1/auth/token", "500").Inc()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "token generation failed"})
			return
		}

		tokenIssued.Inc()
		httpRequests.WithLabelValues("POST", "/api/v1/auth/token", "200").Inc()
		c.JSON(http.StatusOK, TokenResponse{Token: signed, ExpiresAt: expiresAt})
	})

	r.POST("/api/v1/auth/validate", func(c *gin.Context) {
		var body struct {
			Token string `json:"token" binding:"required"`
		}
		if err := c.ShouldBindJSON(&body); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "token required"})
			return
		}

		token, err := jwt.Parse(body.Token, func(t *jwt.Token) (interface{}, error) {
			return []byte(jwtSecret), nil
		})

		if err != nil || !token.Valid {
			httpRequests.WithLabelValues("POST", "/api/v1/auth/validate", "401").Inc()
			c.JSON(http.StatusUnauthorized, gin.H{"valid": false, "error": "invalid token"})
			return
		}

		httpRequests.WithLabelValues("POST", "/api/v1/auth/validate", "200").Inc()
		c.JSON(http.StatusOK, gin.H{"valid": true, "claims": token.Claims})
	})

	log.Printf("auth-service starting on port %s", port)
	_ = context.Background()
	if err := r.Run(":" + port); err != nil {
		log.Fatal(err)
	}
}
