package repositories

import (
	"strings"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

type SuratKeluarRepository struct {
	db *gorm.DB
}

func NewSuratKeluarRepository(db *gorm.DB) *SuratKeluarRepository {
	return &SuratKeluarRepository{db: db}
}

func (r *SuratKeluarRepository) Create(sk *models.SuratKeluar) error {
	return r.db.Create(sk).Error
}

func (r *SuratKeluarRepository) FindByID(id uint) (*models.SuratKeluar, error) {
	var sk models.SuratKeluar
	err := r.db.Where("id_surat_keluar = ?", id).First(&sk).Error
	if err != nil {
		return nil, err
	}
	return &sk, nil
}

func (r *SuratKeluarRepository) Update(sk *models.SuratKeluar) error {
	return r.db.Save(sk).Error
}

func (r *SuratKeluarRepository) Delete(id uint) error {
	return r.db.Where("id_surat_keluar = ?", id).Delete(&models.SuratKeluar{}).Error
}

func (r *SuratKeluarRepository) List(filter dto.SuratKeluarFilter) ([]models.SuratKeluar, error) {
	var list []models.SuratKeluar
	q := r.db.Model(&models.SuratKeluar{})

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
			"no_surat ILIKE ? OR perihal ILIKE ? OR COALESCE(tujuan, '') ILIKE ?",
			like, like, like,
		)
	}

	err := q.Order("created_at DESC").Find(&list).Error
	return list, err
}
