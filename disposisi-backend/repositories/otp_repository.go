package repositories

import (
	"time"

	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

// OTPRepository handles OTP persistence for password reset flow.
type OTPRepository struct {
	db *gorm.DB
}

func NewOTPRepository(db *gorm.DB) *OTPRepository {
	return &OTPRepository{db: db}
}

func (r *OTPRepository) CountRecentByUser(userID uint, since time.Time) (int64, error) {
	var count int64
	err := r.db.Model(&models.OTP{}).
		Where("id_user = ? AND created_at > ?", userID, since).
		Count(&count).Error
	return count, err
}

func (r *OTPRepository) InvalidateActiveByUser(userID uint) error {
	return r.db.Model(&models.OTP{}).
		Where("id_user = ? AND is_used = ?", userID, false).
		Update("is_used", true).Error
}

func (r *OTPRepository) Create(otp *models.OTP) error {
	return r.db.Create(otp).Error
}

// FindLatestActive returns the newest unused OTP that has not expired.
func (r *OTPRepository) FindLatestActive(userID uint) (*models.OTP, error) {
	var otp models.OTP
	err := r.db.
		Where("id_user = ? AND is_used = ? AND expires_at > ?", userID, false, time.Now()).
		Order("created_at DESC").
		First(&otp).Error
	if err != nil {
		return nil, err
	}
	return &otp, nil
}

func (r *OTPRepository) MarkUsed(id uint) error {
	return r.db.Model(&models.OTP{}).Where("id_otp = ?", id).Update("is_used", true).Error
}

func (r *OTPRepository) FindVerifiedWithin(userID uint, since time.Time) (*models.OTP, error) {
	var otp models.OTP
	err := r.db.
		Where("id_user = ? AND is_used = ? AND created_at > ?", userID, true, since).
		Order("created_at DESC").
		First(&otp).Error
	if err != nil {
		return nil, err
	}
	return &otp, nil
}

func (r *OTPRepository) InvalidateAllByUser(userID uint) error {
	return r.db.Model(&models.OTP{}).
		Where("id_user = ?", userID).
		Update("is_used", true).Error
}

func (r *OTPRepository) FindLatestByUser(userID uint) (*models.OTP, error) {
	var otp models.OTP
	err := r.db.
		Where("id_user = ?", userID).
		Order("created_at DESC").
		First(&otp).Error
	if err != nil {
		return nil, err
	}
	return &otp, nil
}

// FIX: Delete menghapus OTP dari database (untuk rollback saat email gagal)
func (r *OTPRepository) Delete(id uint) error {
	return r.db.Delete(&models.OTP{}, id).Error
}