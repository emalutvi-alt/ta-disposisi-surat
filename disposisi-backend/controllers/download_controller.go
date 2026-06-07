package controllers

import (
	"net/http"
	"path/filepath"

	"github.com/fiorelln/disposisi/helpers"
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

type DownloadController struct {
	log *services.LogService
}

func NewDownloadController(log *services.LogService) *DownloadController {
	return &DownloadController{log: log}
}

func (h *DownloadController) Download(c *gin.Context) {
	filename := c.Param("filename")
	if filename == "" {
		utils.ErrorBadRequest(c, "validation failed", map[string]string{"filename": "nama file wajib"})
		return
	}

	fullPath, err := helpers.ResolveUploadByBasename(filename)
	if err != nil {
		utils.Error(c, http.StatusNotFound, "file tidak ditemukan", nil)
		return
	}

	if userID, err := utils.GetUserID(c); err == nil {
		h.log.WriteAuditLog(services.AuditLogInput{
			UserID:   &userID,
			Action:   services.AuditDownloadFile,
			Table:    "uploads",
			NewValue: filename,
		})
	}

	c.FileAttachment(fullPath, filepath.Base(fullPath))
}
