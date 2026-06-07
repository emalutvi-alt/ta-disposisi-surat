package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// APIResponse is the standard envelope for all REST responses.
type APIResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
	Errors  interface{} `json:"errors,omitempty"`
}

func Success(c *gin.Context, status int, message string, data interface{}) {
	c.JSON(status, APIResponse{
		Success: true,
		Message: message,
		Data:    data,
	})
}

func SuccessOK(c *gin.Context, message string, data interface{}) {
	Success(c, http.StatusOK, message, data)
}

func Error(c *gin.Context, status int, message string, errors interface{}) {
	c.JSON(status, APIResponse{
		Success: false,
		Message: message,
		Errors:  errors,
	})
}

func ErrorBadRequest(c *gin.Context, message string, errors interface{}) {
	Error(c, http.StatusBadRequest, message, errors)
}

func ErrorUnauthorized(c *gin.Context, message string) {
	Error(c, http.StatusUnauthorized, message, nil)
}

func ErrorForbidden(c *gin.Context, message string) {
	Error(c, http.StatusForbidden, message, nil)
}

func ErrorNotFound(c *gin.Context, message string) {
	Error(c, http.StatusNotFound, message, nil)
}

func ErrorTooManyRequests(c *gin.Context, message string) {
	Error(c, http.StatusTooManyRequests, message, nil)
}

func ErrorInternal(c *gin.Context, message string) {
	Error(c, http.StatusInternalServerError, message, nil)
}

func ErrorNotImplemented(c *gin.Context, message string) {
	Error(c, http.StatusNotImplemented, message, nil)
}
