package controllers

import (
	"github.com/fiorelln/disposisi/dto"
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
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	level, err := utils.GetLevelAkses(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}

	data, err := h.svc.GetStats(userID, level)
	if err != nil {
		utils.ErrorBadRequest(c, err.Error(), nil)
		return
	}
	utils.SuccessOK(c, "Data berhasil diambil", data)
}

func (h *DashboardController) Aktif(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	role, err := utils.GetRole(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	data, err := h.svc.ListAktif(userID, role)
	if err != nil {
		utils.ErrorBadRequest(c, err.Error(), nil)
		return
	}
	utils.SuccessOK(c, "Data berhasil diambil", data)
}

func (h *DashboardController) Riwayat(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	role, err := utils.GetRole(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	data, err := h.svc.ListRiwayat(userID, role, dto.RiwayatFilterQuery{
		Filter:  c.Query("filter"),
		Tanggal: c.Query("tanggal"),
	})
	if err != nil {
		utils.ErrorBadRequest(c, err.Error(), nil)
		return
	}
	utils.SuccessOK(c, "Data berhasil diambil", data)
}
