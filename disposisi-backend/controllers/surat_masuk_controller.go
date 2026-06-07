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

type SuratMasukController struct {
	svc *services.SuratMasukService
}

func NewSuratMasukController(svc *services.SuratMasukService) *SuratMasukController {
	return &SuratMasukController{svc: svc}
}

func (h *SuratMasukController) Create(c *gin.Context) {
	var req dto.CreateSuratMasukRequest
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

func (h *SuratMasukController) List(c *gin.Context) {
	filter := dto.SuratMasukFilter{
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
	utils.SuccessOK(c, "success", list)
}

func (h *SuratMasukController) GetByID(c *gin.Context) {
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

func (h *SuratMasukController) Update(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	var req dto.UpdateSuratMasukRequest
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

func (h *SuratMasukController) Delete(c *gin.Context) {
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

func (h *SuratMasukController) Verifikasi(c *gin.Context) {
	id, err := parseIDParam(c)
	if err != nil {
		return
	}
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "unauthorized")
		return
	}
	var req dto.VerifikasiSuratMasukRequest
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

func (h *SuratMasukController) handleSuratError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrSuratNotFound):
		utils.Error(c, http.StatusNotFound, "surat tidak ditemukan", nil)
	default:
		utils.ErrorBadRequest(c, "validation failed", err.Error())
	}
}
// Tambah method GetPages
func (h *SuratMasukController) GetPages(c *gin.Context) {
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