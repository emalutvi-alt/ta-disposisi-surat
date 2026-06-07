package utils

import (
	"errors"

	"github.com/gin-gonic/gin"
)

var (
	ErrUnauthorized = errors.New("unauthorized")
	ErrInvalidCtx   = errors.New("invalid context value")
)

// GetUserID reads authenticated user id from Gin context (set by AuthMiddleware).
func GetUserID(c *gin.Context) (uint, error) {
	v, ok := c.Get("user_id")
	if !ok {
		return 0, ErrUnauthorized
	}
	id, ok := v.(uint)
	if !ok {
		return 0, ErrInvalidCtx
	}
	return id, nil
}

// GetUserEmail returns email from JWT claims stored in context.
func GetUserEmail(c *gin.Context) (string, error) {
	v, ok := c.Get("email")
	if !ok {
		return "", ErrUnauthorized
	}
	email, ok := v.(string)
	if !ok {
		return "", ErrInvalidCtx
	}
	return email, nil
}

// GetRole returns Flutter role from JWT (tu | kepsek | users).
func GetRole(c *gin.Context) (string, error) {
	v, ok := c.Get("role")
	if !ok {
		return "", ErrUnauthorized
	}
	role, ok := v.(string)
	if !ok {
		return "", ErrInvalidCtx
	}
	return role, nil
}

// GetLevelAkses returns database level_akses derived from JWT role (for RBAC middleware).
func GetLevelAkses(c *gin.Context) (string, error) {
	v, ok := c.Get("level_akses")
	if !ok {
		return "", ErrUnauthorized
	}
	level, ok := v.(string)
	if !ok {
		return "", ErrInvalidCtx
	}
	return level, nil
}

// GetFlutterRole is an alias for GetRole (backward compatibility).
func GetFlutterRole(c *gin.Context) (string, error) {
	return GetRole(c)
}
