package repositories

import (
	"strings"

	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

type LogRepository struct {
	db *gorm.DB
}

func NewLogRepository(db *gorm.DB) *LogRepository {
	return &LogRepository{db: db}
}

func (r *LogRepository) Create(entry *models.Log) error {
	return r.db.Create(entry).Error
}

type AuditLogListParams struct {
	Page   int
	Limit  int
	Search string
}

func (r *LogRepository) List(p AuditLogListParams) ([]models.Log, int64, error) {
	q := r.db.Model(&models.Log{})

	if s := strings.TrimSpace(p.Search); s != "" {
		like := "%" + s + "%"
		q = q.Where("aksi ILIKE ? OR tabel_terkait ILIKE ?", like, like)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (p.Page - 1) * p.Limit
	var list []models.Log
	err := q.Order("updated_at DESC").Offset(offset).Limit(p.Limit).Find(&list).Error
	return list, total, err
}
