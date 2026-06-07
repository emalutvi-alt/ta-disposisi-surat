package helpers

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/fiorelln/disposisi/config"
	"github.com/golang-jwt/jwt/v5"
)

var ErrInvalidResetToken = errors.New("reset token tidak valid atau kedaluwarsa")

// TokenClaims holds JWT payload: user_id, email, role (Flutter-mapped).
type TokenClaims struct {
	UserID uint
	Email  string
	Role   string // tu | kepsek | users
}

// GenerateToken creates HS256 JWT with user_id, email, and role.
func GenerateToken(claims TokenClaims) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": float64(claims.UserID),
		"email":   claims.Email,
		"role":    claims.Role,
		"exp":     time.Now().Add(168 * time.Hour).Unix(),
	})

	return token.SignedString(config.JwtKey)
}

// GenerateResetToken issues a short-lived JWT after OTP verification (password reset session).
func GenerateResetToken(userID uint, email string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": float64(userID),
		"email":   email,
		"purpose": "password_reset",
		"exp":     time.Now().Add(5 * time.Minute).Unix(),
	})
	return token.SignedString(config.JwtKey)
}

// ValidateResetToken verifies short-lived password reset JWT and returns user id.
func ValidateResetToken(tokenString, email string) (uint, error) {
	tokenString = strings.TrimSpace(tokenString)
	if tokenString == "" {
		return 0, ErrInvalidResetToken
	}

	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if token.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("unexpected signing method")
		}
		return config.JwtKey, nil
	})
	if err != nil || !token.Valid {
		return 0, ErrInvalidResetToken
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return 0, ErrInvalidResetToken
	}
	purpose, _ := claims["purpose"].(string)
	if purpose != "password_reset" {
		return 0, ErrInvalidResetToken
	}
	claimEmail, _ := claims["email"].(string)
	if !strings.EqualFold(strings.TrimSpace(claimEmail), strings.TrimSpace(email)) {
		return 0, ErrInvalidResetToken
	}

	switch v := claims["user_id"].(type) {
	case float64:
		if v < 1 {
			return 0, ErrInvalidResetToken
		}
		return uint(v), nil
	default:
		return 0, ErrInvalidResetToken
	}
}
