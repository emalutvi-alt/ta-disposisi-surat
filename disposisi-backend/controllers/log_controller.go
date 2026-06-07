package controllers

import (
	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

type LogController struct {
	log *services.LogService
}

func NewLogController(log *services.LogService) *LogController {
	return &LogController{log: log}
}

// ListAudit GET /log — admin monitoring (read-only, no delete).
func (h *LogController) ListAudit(c *gin.Context) {
	q := dto.AuditLogListQuery{
		Page:   queryInt(c, "page", 1),
		Limit:  queryInt(c, "limit", 20),
		Search: c.Query("search"),
	}
	data, err := h.log.ListAuditLogs(q)
	if err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}
	utils.SuccessOK(c, "success", data)
}


