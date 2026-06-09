package repositories

import (
	"time"

	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

type DistribusiSMRepository struct {
	db *gorm.DB
}

func NewDistribusiSMRepository(db *gorm.DB) *DistribusiSMRepository {
	return &DistribusiSMRepository{db: db}
}

func (r *DistribusiSMRepository) WithTx(tx *gorm.DB) *DistribusiSMRepository {
	return &DistribusiSMRepository{db: tx}
}

func (r *DistribusiSMRepository) CreateBatch(rows []models.DistribusiSM) error {
	if len(rows) == 0 {
		return nil
	}
	return r.db.Create(&rows).Error
}

func (r *DistribusiSMRepository) MarkRead(disposisiID, userID uint, readAt interface{}) error {
	return r.db.Model(&models.DistribusiSM{}).
		Where("id_disposisi = ? AND id_user = ?", disposisiID, userID).
		Updates(map[string]interface{}{
			"status":  "dibaca",
			"read_at": readAt,
		}).Error
}

func (r *DistribusiSMRepository) MarkRiwayatUserBySurat(suratMasukID, userID uint, readAt time.Time) (bool, error) {
	result := r.db.Model(&models.DistribusiSM{}).
		Where(`id_user = ? AND id_disposisi IN (
			SELECT id_disposisi FROM disposisi WHERE id_surat_masuk = ?
		)`, userID, suratMasukID).
		Updates(map[string]interface{}{
			"status":       "DITERIMA_USER",
			"read_at":      readAt,
			"riwayat_user": true,
		})
	return result.RowsAffected > 0, result.Error
}
