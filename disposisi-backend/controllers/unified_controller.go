package controllers

import (
	"errors"
	"net/http"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

// UnifiedController handles the unified disposisi + verifikasi endpoints.
type UnifiedController struct {
	unifiedSvc *services.UnifiedService
}

// NewUnifiedController creates a new UnifiedController.
func NewUnifiedController(unifiedSvc *services.UnifiedService) *UnifiedController {
	return &UnifiedController{unifiedSvc: unifiedSvc}
}

// ── SURAT MASUK ────────────────────────────────────────────────────────────

func (h *UnifiedController) ProcessSuratMasukDisposisi(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}

	id, err := parseIDParam(c)
	if err != nil {
		return
	}

	var req dto.UnifiedDisposisiRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorBadRequest(c, "Validasi gagal", err.Error())
		return
	}

	if req.Status == "ditolak" && req.Catatan == "" {
		utils.ErrorBadRequest(c, "Catatan Kepala Sekolah wajib diisi", nil)
		return
	}

	result, err := h.unifiedSvc.ProcessSuratMasukDisposisi(userID, id, req)
	if err != nil {
		if errors.Is(err, services.ErrSuratNotFound) {
			utils.Error(c, http.StatusNotFound, err.Error(), nil)
			return
		}
		utils.ErrorInternal(c, err.Error())
		return
	}

	utils.SuccessOK(c, "disposisi berhasil diproses", result)
}

// ── SURAT KELUAR ───────────────────────────────────────────────────────────

func (h *UnifiedController) ProcessSuratKeluarVerifikasi(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}

	id, err := parseIDParam(c)
	if err != nil {
		return
	}

	var req dto.UnifiedDisposisiRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorBadRequest(c, "Validasi gagal", err.Error())
		return
	}

	if req.Status == "ditolak" && req.Catatan == "" {
		utils.ErrorBadRequest(c, "Catatan Kepala Sekolah wajib diisi", nil)
		return
	}

	result, err := h.unifiedSvc.ProcessSuratKeluarVerifikasi(userID, id, req)
	if err != nil {
		if errors.Is(err, services.ErrSuratNotFound) {
			utils.Error(c, http.StatusNotFound, err.Error(), nil)
			return
		}
		utils.ErrorInternal(c, err.Error())
		return
	}

	utils.SuccessOK(c, "verifikasi berhasil diproses", result)
}

// ── USER READ SURAT ────────────────────────────────────────────────────────

func (h *UnifiedController) MarkSuratAsRead(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}

	id, err := parseIDParam(c)
	if err != nil {
		return
	}

	jenis := c.Query("jenis")
	if jenis != "masuk" && jenis != "keluar" {
		utils.ErrorBadRequest(c, "jenis surat harus 'masuk' atau 'keluar'", nil)
		return
	}

	if err := h.unifiedSvc.MarkSuratAsRead(userID, id, jenis); err != nil {
		utils.ErrorInternal(c, err.Error())
		return
	}

	utils.SuccessOK(c, "surat berhasil ditandai sebagai dibaca", nil)
}
