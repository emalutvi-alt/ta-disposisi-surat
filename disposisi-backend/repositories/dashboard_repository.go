package repositories

import (
	"gorm.io/gorm"
)

type DashboardRepository struct {
	db *gorm.DB
}

func NewDashboardRepository(db *gorm.DB) *DashboardRepository {
	return &DashboardRepository{db: db}
}

func (r *DashboardRepository) CountSuratMasuk() (int64, error) {
	var n int64
	err := r.db.Table("surat_masuk").Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountSuratKeluar() (int64, error) {
	var n int64
	err := r.db.Table("surat_keluar").Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountDisposisi() (int64, error) {
	var n int64
	err := r.db.Table("disposisi").Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountSuratSelesai() (int64, error) {
	var n int64
	err := r.db.Table("surat_masuk").Where("status_alur = ?", "selesai").Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountPendingDisposisiForUser(userID uint) (int64, error) {
	var n int64
	err := r.db.Table("disposisi").
		Where("id_penerima = ? AND status_approval = ?", userID, "menunggu").
		Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountPendingSuratVerifikasi() (int64, error) {
	var n int64
	err := r.db.Table("surat_masuk").Where("status_verifikasi = ?", "menunggu").Count(&n).Error
	return n, err
}
