package controllers

import (
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

type DashboardController struct {
	svc *services.DashboardService
}

func NewDashboardController(svc *services.DashboardService) *DashboardController {
	return &DashboardController{svc: svc}
}

func (h *DashboardController) Stats(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	level, err := utils.GetLevelAkses(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}

	data, err := h.svc.GetStats(userID, level)
	if err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}
	utils.SuccessOK(c, "success", data)
}
