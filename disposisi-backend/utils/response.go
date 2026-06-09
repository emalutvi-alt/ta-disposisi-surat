package utils

import (
	"net/http"

	"github.com/fiorelln/disposisi/pkg/response"
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
	c.JSON(status, response.APIResponse{Success: true, Message: message, Data: data})
}

func SuccessOK(c *gin.Context, message string, data interface{}) {
	response.Success(c, message, data)
}

func Error(c *gin.Context, status int, message string, errors interface{}) {
	c.JSON(status, response.APIResponse{Success: false, Message: message, Errors: errors})
}

func ErrorBadRequest(c *gin.Context, message string, errors interface{}) {
	response.BadRequest(c, message, errors)
}

func ErrorUnauthorized(c *gin.Context, message string) {
	response.Unauthorized(c, message)
}

func ErrorForbidden(c *gin.Context, message string) {
	response.Forbidden(c, message)
}

func ErrorNotFound(c *gin.Context, message string) {
	response.NotFound(c, message)
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
