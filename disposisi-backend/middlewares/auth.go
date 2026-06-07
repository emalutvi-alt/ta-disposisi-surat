package middlewares

import (
	"encoding/json"
	"fmt"
	"log"
	"strings"

	"github.com/fiorelln/disposisi/config"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const bearerPrefix = "Bearer "

// AuthMiddleware validates Bearer JWT and stores typed claims in Gin context.
func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := strings.TrimSpace(c.GetHeader("Authorization"))

		log.Printf("[AuthMiddleware] %s %s | Authorization present: %v",
			c.Request.Method, c.Request.URL.Path, authHeader != "")

		if authHeader == "" {
			abortUnauthorized(c, "missing Authorization header")
			return
		}

		if !strings.HasPrefix(authHeader, bearerPrefix) {
			abortUnauthorized(c, "invalid Authorization format (expected Bearer)")
			return
		}

		tokenString := strings.TrimSpace(strings.TrimPrefix(authHeader, bearerPrefix))
		if tokenString == "" {
			abortUnauthorized(c, "empty bearer token")
			return
		}

		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			if token.Method != jwt.SigningMethodHS256 {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return config.JwtKey, nil
		})
		if err != nil || !token.Valid {
			log.Printf("[AuthMiddleware] JWT parse error: %v", err)
			abortUnauthorized(c, "invalid or expired token")
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			abortUnauthorized(c, "invalid token claims")
			return
		}

		userID, err := parseClaimUserID(claims["user_id"])
		if err != nil {
			log.Printf("[AuthMiddleware] user_id claim error: %v | raw: %v", err, claims["user_id"])
			abortUnauthorized(c, "invalid user_id claim")
			return
		}

		email, _ := claims["email"].(string)
		role, _ := claims["role"].(string)

		// Reject password-reset tokens on protected routes
		if purpose, _ := claims["purpose"].(string); purpose == "password_reset" {
			log.Printf("[AuthMiddleware] rejected reset token for protected route")
			abortUnauthorized(c, "invalid token type for this route")
			return
		}

		log.Printf("[AuthMiddleware] OK user_id=%d email=%s role=%s level_akses=%s",
			userID, email, role, utils.MapFlutterToLevel(role))

		c.Set("user_id", userID)
		c.Set("email", email)
		c.Set("role", role)
		c.Set("level_akses", utils.MapFlutterToLevel(role))

		c.Next()
	}
}

func abortUnauthorized(c *gin.Context, detail string) {
	log.Printf("[AuthMiddleware] 401 unauthorized: %s", detail)
	utils.ErrorUnauthorized(c, "unauthorized")
	c.Abort()
}

// parseClaimUserID reads user_id from JWT MapClaims (JSON numbers decode as float64).
func parseClaimUserID(raw interface{}) (uint, error) {
	switch v := raw.(type) {
	case float64:
		if v < 1 {
			return 0, fmt.Errorf("user_id must be positive")
		}
		return uint(v), nil
	case int:
		return uint(v), nil
	case int64:
		return uint(v), nil
	case uint:
		return v, nil
	case uint64:
		return uint(v), nil
	case json.Number:
		n, err := v.Int64()
		if err != nil {
			return 0, err
		}
		return uint(n), nil
	default:
		return 0, fmt.Errorf("unsupported type %T", raw)
	}
}
