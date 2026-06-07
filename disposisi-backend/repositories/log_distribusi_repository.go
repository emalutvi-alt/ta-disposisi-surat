package repositories

import (
	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

type LogDistribusiRepository struct {
	db *gorm.DB
}

func NewLogDistribusiRepository(db *gorm.DB) *LogDistribusiRepository {
	return &LogDistribusiRepository{db: db}
}

func (r *LogDistribusiRepository) Create(entry *models.LogDistribusi) error {
	return r.db.Create(entry).Error
}

func (r *LogDistribusiRepository) CreateWithTx(tx *gorm.DB, entry *models.LogDistribusi) error {
	return tx.Create(entry).Error
}
