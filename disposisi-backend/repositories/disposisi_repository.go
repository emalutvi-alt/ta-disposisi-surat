package repositories

import (
	"strings"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/utils"
	"gorm.io/gorm"
)

type DisposisiRepository struct {
	db *gorm.DB
}

func NewDisposisiRepository(db *gorm.DB) *DisposisiRepository {
	return &DisposisiRepository{db: db}
}

func (r *DisposisiRepository) WithTx(tx *gorm.DB) *DisposisiRepository {
	return &DisposisiRepository{db: tx}
}

func (r *DisposisiRepository) CreateBatch(rows []models.Disposisi) error {
	if len(rows) == 0 {
		return nil
	}
	return r.db.Create(&rows).Error
}

func (r *DisposisiRepository) FindByID(id uint) (*models.Disposisi, error) {
	var d models.Disposisi
	err := r.db.
		Preload("Penerima").
		Preload("Kepsek").
		Preload("SuratMasuk").
		Where("id_disposisi = ?", id).
		First(&d).Error
	if err != nil {
		return nil, err
	}
	return &d, nil
}

func (r *DisposisiRepository) ExistsForSuratAndPenerima(suratMasukID, penerimaID uint) (bool, error) {
	var count int64
	err := r.db.Model(&models.Disposisi{}).
		Where("id_surat_masuk = ? AND id_penerima = ?", suratMasukID, penerimaID).
		Count(&count).Error
	return count > 0, err
}

func (r *DisposisiRepository) Update(d *models.Disposisi) error {
	return r.db.Save(d).Error
}

func (r *DisposisiRepository) FindBySuratMasukID(suratMasukID uint) ([]models.Disposisi, error) {
	var list []models.Disposisi
	err := r.db.
		Preload("Penerima").
		Preload("Kepsek").
		Preload("SuratMasuk").
		Where("id_surat_masuk = ?", suratMasukID).
		Order("tanggal_disposisi DESC").
		Find(&list).Error
	return list, err
}

func (r *DisposisiRepository) List(filter dto.DisposisiFilter, scopePenerimaID *uint) ([]models.Disposisi, error) {
	q := r.db.
		Preload("Penerima").
		Preload("Kepsek").
		Preload("SuratMasuk").
		Joins("JOIN surat_masuk sm ON sm.id_surat_masuk = disposisi.id_surat_masuk").
		Joins("JOIN users u ON u.id_user = disposisi.id_penerima")

	if scopePenerimaID != nil {
		q = q.Where("disposisi.id_penerima = ?", *scopePenerimaID)
	}

	if filter.Status != "" {
		if filter.Status == "ditolak" {
			q = q.Where("disposisi.status_approval = ?", "ditolak")
		} else if db := utils.MapAPIStatusToDB(filter.Status); db != "" {
			if filter.Status == "diterima" {
				q = q.Where("disposisi.status_disposisi IN ?", []string{"dibaca", "sedang_dikerjakan"})
			} else {
				q = q.Where("disposisi.status_disposisi = ?", db)
			}
		}
	}

	if filter.VerificationStatus != "" {
		q = q.Where("disposisi.status_approval = ?", filter.VerificationStatus)
	}

	if filter.TanggalAwal != "" {
		if t, err := time.Parse("2006-01-02", filter.TanggalAwal); err == nil {
			q = q.Where("disposisi.tanggal_disposisi >= ?", t)
		}
	}
	if filter.TanggalAkhir != "" {
		if t, err := time.Parse("2006-01-02", filter.TanggalAkhir); err == nil {
			end := t.Add(24*time.Hour - time.Nanosecond)
			q = q.Where("disposisi.tanggal_disposisi <= ?", end)
		}
	}

	if s := strings.TrimSpace(filter.Search); s != "" {
		like := "%" + s + "%"
		q = q.Where(
			"sm.no_surat ILIKE ? OR sm.perihal_surat ILIKE ? OR u.nama ILIKE ?",
			like, like, like,
		)
	}

	var list []models.Disposisi
	err := q.Order("disposisi.tanggal_disposisi DESC").Find(&list).Error
	return list, err
}

func (r *DisposisiRepository) CountSelesaiBySurat(suratMasukID uint) (total, selesai int64, err error) {
	err = r.db.Model(&models.Disposisi{}).
		Where("id_surat_masuk = ?", suratMasukID).
		Count(&total).Error
	if err != nil {
		return
	}
	err = r.db.Model(&models.Disposisi{}).
		Where("id_surat_masuk = ? AND status_disposisi = ?", suratMasukID, "selesai").
		Count(&selesai).Error
	return
}
