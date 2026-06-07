package repositories

import (
	"strings"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

type SuratMasukRepository struct {
	db *gorm.DB
}

func NewSuratMasukRepository(db *gorm.DB) *SuratMasukRepository {
	return &SuratMasukRepository{db: db}
}

func (r *SuratMasukRepository) Create(sm *models.SuratMasuk) error {
	return r.db.Create(sm).Error
}

func (r *SuratMasukRepository) FindByID(id uint) (*models.SuratMasuk, error) {
	var sm models.SuratMasuk
	err := r.db.Where("id_surat_masuk = ?", id).First(&sm).Error
	if err != nil {
		return nil, err
	}
	return &sm, nil
}

func (r *SuratMasukRepository) Update(sm *models.SuratMasuk) error {
	return r.db.Save(sm).Error
}

func (r *SuratMasukRepository) Delete(id uint) error {
	return r.db.Where("id_surat_masuk = ?", id).Delete(&models.SuratMasuk{}).Error
}

func (r *SuratMasukRepository) List(filter dto.SuratMasukFilter) ([]models.SuratMasuk, error) {
	var list []models.SuratMasuk
	q := r.db.Model(&models.SuratMasuk{})

	// ── ARSIP FILTER ──────────────────────────────────────────────────────
	if filter.ArsipOnly {
		q = q.Where("is_arsip = ?", true)
	} else {
		q = q.Where("is_arsip = ?", false) // Default: tidak tampilkan arsip
	}

	if filter.Status != "" {
		q = q.Where("status_verifikasi = ?", filter.Status)
	}
	if filter.TanggalAwal != "" {
		if t, err := time.Parse("2006-01-02", filter.TanggalAwal); err == nil {
			q = q.Where("tanggal_surat >= ?", t)
		}
	}
	if filter.TanggalAkhir != "" {
		if t, err := time.Parse("2006-01-02", filter.TanggalAkhir); err == nil {
			q = q.Where("tanggal_surat <= ?", t)
		}
	}
	if s := strings.TrimSpace(filter.Search); s != "" {
		like := "%" + s + "%"
		q = q.Where(
			"no_surat ILIKE ? OR perihal_surat ILIKE ? OR asal_surat ILIKE ?",
			like, like, like,
		)
	}

	err := q.Order("created_at DESC").Find(&list).Error
	return list, err
}
