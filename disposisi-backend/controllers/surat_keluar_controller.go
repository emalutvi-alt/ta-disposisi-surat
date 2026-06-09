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
		utils.ErrorBadRequest(c, "Validasi gagal", err.Error())
		return
	}

	file, err := c.FormFile("file")
	if err != nil {
		utils.ErrorBadRequest(c, "File wajib diupload", nil)
		return
	}

	actorID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	data, err := h.svc.Create(actorID, req, file)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "Surat keluar berhasil diupload", data)
}

func (h *SuratKeluarController) List(c *gin.Context) {
	filter := dto.SuratKeluarFilter{
		Status:       c.Query("status"),
		TanggalAwal:  c.Query("tanggal_awal"),
		TanggalAkhir: c.Query("tanggal_akhir"),
		Search:       c.Query("search"),
	}
	list, err := h.svc.List(filter)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "Data berhasil diambil", list)
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
	utils.SuccessOK(c, "Data berhasil diambil", data)
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
		utils.ErrorUnauthorized(c, "Akses tidak sah")
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
		utils.ErrorUnauthorized(c, "Akses tidak sah")
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
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	var req dto.VerifikasiSuratKeluarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorBadRequest(c, "Validasi gagal", err.Error())
		return
	}
	data, err := h.svc.Verifikasi(id, userID, req)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "Verifikasi surat berhasil diproses", data)
}

func (h *SuratKeluarController) KonfirmasiTU(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	data, err := h.svc.KonfirmasiTU(userID, id)
	if err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "Konfirmasi TU berhasil diproses", data)
}

func (h *SuratKeluarController) Distribusi(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	var req dto.DistribusiSuratKeluarRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ErrorBadRequest(c, "Validasi gagal", err.Error())
		return
	}
	actorID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	if err := h.svc.Distribusi(actorID, id, req); err != nil {
		h.handleSuratError(c, err)
		return
	}
	utils.SuccessOK(c, "Data berhasil disimpan", nil)
}

func (h *SuratKeluarController) handleSuratError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrSuratNotFound):
		utils.Error(c, http.StatusNotFound, "surat tidak ditemukan", nil)
	default:
		utils.ErrorBadRequest(c, err.Error(), nil)
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
	utils.SuccessOK(c, "Data berhasil diambil", gin.H{
		"surat_id":    id,
		"total_pages": len(pages),
		"pages":       pages,
	})
}
