package repositories

import (
	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

type DistribusiSKRepository struct {
	db *gorm.DB
}

func NewDistribusiSKRepository(db *gorm.DB) *DistribusiSKRepository {
	return &DistribusiSKRepository{db: db}
}

func (r *DistribusiSKRepository) CreateBatch(rows []models.DistribusiSK) error {
	if len(rows) == 0 {
		return nil
	}
	return r.db.Create(&rows).Error
}

func (r *DistribusiSKRepository) FindBySuratKeluarID(skID uint) ([]models.DistribusiSK, error) {
	var list []models.DistribusiSK
	err := r.db.Where("id_sk = ?", skID).Order("distribute_at DESC").Find(&list).Error
	return list, err
}
