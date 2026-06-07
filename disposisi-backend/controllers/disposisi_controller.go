package controllers

import (
	"errors"
	"net/http"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

type DisposisiController struct {
	svc *services.DisposisiService
}

func NewDisposisiController(svc *services.DisposisiService) *DisposisiController {
	return &DisposisiController{svc: svc}
}

func (h *DisposisiController) Create(c *gin.Context) {
	var req dto.CreateDisposisiRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}

	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}

	result, err := h.svc.Create(userID, req)
	if err != nil {
		if errors.Is(err, services.ErrInvalidTujuan) || errors.Is(err, services.ErrDuplicatePenerima) || errors.Is(err, services.ErrSuratBelumDisetujui) {
			utils.ErrorBadRequest(c, err.Error(), nil)
			return
		}
		utils.ErrorInternal(c, err.Error())
		return
	}

	utils.SuccessOK(c, "disposisi berhasil dibuat", result)
}

func (h *DisposisiController) List(c *gin.Context) {
	filter := dto.DisposisiFilter{
		Status:             c.Query("status"),
		VerificationStatus: c.Query("verification_status"),
		Search:             c.Query("search"),
		TanggalAwal:        c.Query("tanggal_awal"),
		TanggalAkhir:       c.Query("tanggal_akhir"),
	}

	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}

	role, err := utils.GetRole(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}

	list, err := h.svc.List(filter, userID, role)
	if err != nil {
		utils.ErrorInternal(c, err.Error())
		return
	}

	utils.SuccessOK(c, "success", list)
}

func (h *DisposisiController) ListBySurat(c *gin.Context) {
	suratID, err := parseIDParam(c)
	if err != nil {
		return
	}

	list, err := h.svc.ListBySurat(suratID)
	if err != nil {
		utils.ErrorInternal(c, err.Error())
		return
	}

	utils.SuccessOK(c, "success", list)
}

func (h *DisposisiController) Approve(c *gin.Context) {
	disposisiID, err := parseIDParam(c)
	if err != nil {
		return
	}

	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}

	var req struct {
		IsApproved bool   `json:"is_approved"`
		Catatan    string `json:"catatan"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}

	err = h.svc.Approve(userID, disposisiID, req.IsApproved, req.Catatan)
	if err != nil {
		if errors.Is(err, services.ErrDisposisiNotFound) {
			utils.Error(c, http.StatusNotFound, err.Error(), nil)
			return
		}
		utils.ErrorInternal(c, err.Error())
		return
	}

	utils.SuccessOK(c, "disposisi berhasil diproses", nil)
}

func (h *DisposisiController) MarkSelesai(c *gin.Context) {
	disposisiID, err := parseIDParam(c)
	if err != nil {
		return
	}

	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}

	err = h.svc.MarkSelesai(userID, disposisiID)
	if err != nil {
		if errors.Is(err, services.ErrDisposisiNotFound) {
			utils.Error(c, http.StatusNotFound, err.Error(), nil)
			return
		}
		if errors.Is(err, services.ErrDisposisiForbidden) {
			utils.ErrorForbidden(c, err.Error())
			return
		}
		utils.ErrorInternal(c, err.Error())
		return
	}

	utils.SuccessOK(c, "disposisi selesai", nil)
}
