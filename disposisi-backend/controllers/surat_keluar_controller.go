package controllers

import (
	"errors"
	"mime/multipart"
	"net/http"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
)

type SuratKeluarController struct {
	svc *services.SuratKeluarService
}

func NewSuratKeluarController(svc *services.SuratKeluarService) *SuratKeluarController {
	return &SuratKeluarController{svc: svc}
}

func (h *SuratKeluarController) Create(c *gin.Context) {
	var req dto.CreateSuratKeluarRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}

	file, err := c.FormFile("file")
	if err != nil {
		utils.ErrorBadRequest(c, "validation failed", map[string]string{"file": "file wajib diupload"})
		return
	}

	actorID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	data, err := h.svc.Create(actorID, req, file)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", data)
}

func (h *SuratKeluarController) List(c *gin.Context) {
	filter := dto.SuratKeluarFilter{
		Status:       c.Query("status"),
		TanggalAwal:  c.Query("tanggal_awal"),
		TanggalAkhir: c.Query("tanggal_akhir"),
		Search:       c.Query("search"),
		ArsipOnly:    c.Query("arsip") == "true", // ← NEW
	}
	list, err := h.svc.List(filter)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", list)
}

func (h *SuratKeluarController) GetByID(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	data, err := h.svc.GetByID(id)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", data)
}

func (h *SuratKeluarController) Update(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	var req dto.UpdateSuratKeluarRequest
	if err := c.ShouldBind(&req); err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}
	var file *multipart.FileHeader
	if f, ferr := c.FormFile("file"); ferr == nil {
		file = f
	}
	actorID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	data, err := h.svc.Update(actorID, id, req, file)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", data)
}

func (h *SuratKeluarController) Delete(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	actorID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	if err := h.svc.Delete(actorID, id); err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", nil)
}

func (h *SuratKeluarController) Verifikasi(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	var req dto.VerifikasiSuratKeluarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}
	data, err := h.svc.Verifikasi(id, userID, req)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", data)
}

func (h *SuratKeluarController) Distribusi(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	var req dto.DistribusiSuratKeluarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorBadRequest(c, "validation failed", err.Error())
		return
	}
	actorID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	if err := h.svc.Distribusi(actorID, id, req); err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", nil)
}

func (h *SuratKeluarController) handleSuratError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrSuratNotFound):
		utils.Error(c, http.StatusNotFound, "surat tidak ditemukan", nil)
	default:
		utils.ErrorBadRequest(c, "validation failed", err.Error())
	}
}

// GetPages mengembalikan semua halaman preview PDF untuk satu surat keluar.
func (h *SuratKeluarController) GetPages(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	pages, err := h.svc.GetPages(id)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", gin.H{
		"surat_id":    id,
		"total_pages": len(pages),
		"pages":       pages,
	})
}

// ── ARSIP METHODS ────────────────────────────────────────────────────────

// Arsipkan POST /surat-keluar/:id/arsip
func (h *SuratKeluarController) Arsipkan(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	actorID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	if err := h.svc.Arsipkan(actorID, id); err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "surat berhasil diarsipkan", nil)
}

// RestoreArsip POST /surat-keluar/:id/restore
func (h *SuratKeluarController) RestoreArsip(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	actorID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	if err := h.svc.RestoreArsip(actorID, id); err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "surat berhasil dikembalikan dari arsip", nil)
}

// ListArsip GET /arsip/surat-keluar
func (h *SuratKeluarController) ListArsip(c *gin.Context) {
	filter := dto.SuratKeluarFilter{
		ArsipOnly: true,
		Status:    c.Query("status"),
		Search:    c.Query("search"),
	}
	list, err := h.svc.List(filter)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "success", list)
}
