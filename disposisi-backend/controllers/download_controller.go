package controllers

import (
	"errors"
	"net/http"
	"path/filepath"
	"strconv"

	"github.com/fiorelln/disposisi/config"
	"github.com/fiorelln/disposisi/helpers"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

type DownloadController struct {
	log *services.LogService
}

func NewDownloadController(log *services.LogService) *DownloadController {
	return &DownloadController{log: log}
}

func (h *DownloadController) Download(c *gin.Context) {
	utils.ErrorNotFound(c, "Endpoint download file asli tidak tersedia")
}

func (h *DownloadController) DownloadSuratMasukPreview(c *gin.Context) {
	h.downloadPreview(c, "masuk")
}

func (h *DownloadController) DownloadSuratKeluarPreview(c *gin.Context) {
	h.downloadPreview(c, "keluar")
}

func (h *DownloadController) downloadPreview(c *gin.Context, suratType string) {
	suratID, err := parseIDParam(c)
	if err != nil {
		return
	}
	page, err := strconv.Atoi(c.Param("page"))
	if err != nil || page < 1 {
		utils.ErrorBadRequest(c, "Nomor halaman preview tidak valid", nil)
		return
	}
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}
	role := ""
	if v, ok := c.Get("role"); ok {
		role, _ = v.(string)
	}
	if err := h.ensurePreviewPermission(userID, role, suratType, suratID); err != nil {
		utils.ErrorForbidden(c, "Akses download preview ditolak")
		return
	}

	relPath, err := h.findPreviewPath(suratType, suratID, page)
	if err != nil {
		utils.Error(c, http.StatusNotFound, "Preview tidak ditemukan", nil)
		return
	}
	fullPath, err := helpers.ResolvePreviewPath(relPath)
	if err != nil {
		utils.ErrorForbidden(c, "Akses file preview ditolak")
		return
	}

	h.log.WriteAuditLog(services.AuditLogInput{
		UserID: &userID, Role: role, Action: services.AuditDownloadPreview, Table: "pdf_previews",
		RecordID: &suratID, NewValue: relPath, IPAddress: c.ClientIP(), UserAgent: c.Request.UserAgent(),
	})

	c.FileAttachment(fullPath, filepath.Base(fullPath))
}

func (h *DownloadController) findPreviewPath(suratType string, suratID uint, page int) (string, error) {
	var preview models.PDFPreview
	err := config.DB.Where("surat_type = ? AND surat_id = ? AND page_number = ?", suratType, suratID, page).First(&preview).Error
	if err == nil {
		return preview.ImagePath, nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) || page != 1 {
		return "", err
	}
	if suratType == "masuk" {
		var sm models.SuratMasuk
		if err := config.DB.Where("id_surat_masuk = ?", suratID).First(&sm).Error; err != nil {
			return "", err
		}
		if sm.FilePreview != nil {
			return *sm.FilePreview, nil
		}
	} else {
		var sk models.SuratKeluar
		if err := config.DB.Where("id_surat_keluar = ?", suratID).First(&sk).Error; err != nil {
			return "", err
		}
		if sk.FilePreview != nil {
			return *sk.FilePreview, nil
		}
	}
	return "", gorm.ErrRecordNotFound
}

func (h *DownloadController) ensurePreviewPermission(userID uint, role, suratType string, suratID uint) error {
	switch role {
	case utils.FlutterTU:
		return nil
	case utils.FlutterKepsek:
		if suratType == "masuk" {
			return config.DB.Where("id_surat_masuk = ? AND status_alur IN ?", suratID, []string{utils.StatusMenungguPersetujuanKepsek, utils.StatusDisetujuiKepsek, utils.StatusDitolakKepsek}).First(&models.SuratMasuk{}).Error
		}
		return config.DB.Where("id_surat_keluar = ? AND status_alur IN ?", suratID, []string{utils.StatusMenungguPersetujuanKepsek, utils.StatusDisetujuiKepsek, utils.StatusDitolakKepsek}).First(&models.SuratKeluar{}).Error
	case utils.FlutterUsers:
		if suratType == "masuk" {
			var count int64
			err := config.DB.Model(&models.DistribusiSM{}).
				Joins("JOIN disposisi d ON d.id_disposisi = distribusi_sm.id_disposisi").
				Where("d.id_surat_masuk = ? AND distribusi_sm.id_user = ?", suratID, userID).
				Count(&count).Error
			if err != nil {
				return err
			}
			if count == 0 {
				return gorm.ErrRecordNotFound
			}
			return nil
		}
		var count int64
		err := config.DB.Model(&models.DistribusiSK{}).
			Where("id_sk = ? AND id_user = ?", suratID, userID).
			Count(&count).Error
		if err != nil {
			return err
		}
		if count == 0 {
			return gorm.ErrRecordNotFound
		}
		return nil
	default:
		return gorm.ErrRecordNotFound
	}
}
