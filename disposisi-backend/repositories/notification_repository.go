package repositories

import (
	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

type NotificationRepository struct {
	db *gorm.DB
}

func NewNotificationRepository(db *gorm.DB) *NotificationRepository {
	return &NotificationRepository{db: db}
}

func (r *NotificationRepository) WithTx(tx *gorm.DB) *NotificationRepository {
	return &NotificationRepository{db: tx}
}

func (r *NotificationRepository) Create(n *models.Notifikasi) error {
	return r.db.Create(n).Error
}

func (r *NotificationRepository) FindByIDForPenerima(id, penerimaID uint) (*models.Notifikasi, error) {
	var n models.Notifikasi
	err := r.db.Where("id_notifikasi = ? AND id_penerima = ?", id, penerimaID).First(&n).Error
	if err != nil {
		return nil, err
	}
	return &n, nil
}

type NotificationListParams struct {
	PenerimaID uint
	Page       int
	Limit      int
	UnreadOnly bool
	Type       string
}

func (r *NotificationRepository) List(p NotificationListParams) ([]models.Notifikasi, int64, error) {
	q := r.db.Model(&models.Notifikasi{}).Where("id_penerima = ?", p.PenerimaID)

	if p.UnreadOnly {
		q = q.Where("is_read = ?", false)
	}
	if p.Type != "" {
		q = q.Where("tipe_referensi = ?", p.Type)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	offset := (p.Page - 1) * p.Limit
	var list []models.Notifikasi
	err := q.Order("created_at DESC").Offset(offset).Limit(p.Limit).Find(&list).Error
	return list, total, err
}

func (r *NotificationRepository) CountUnread(penerimaID uint) (int64, error) {
	var count int64
	err := r.db.Model(&models.Notifikasi{}).
		Where("id_penerima = ? AND is_read = ?", penerimaID, false).
		Count(&count).Error
	return count, err
}

func (r *NotificationRepository) MarkAsRead(id, penerimaID uint, readAt interface{}) error {
	return r.db.Model(&models.Notifikasi{}).
		Where("id_notifikasi = ? AND id_penerima = ?", id, penerimaID).
		Updates(map[string]interface{}{
			"is_read":    true,
			"waktu_baca": readAt,
		}).Error
}
