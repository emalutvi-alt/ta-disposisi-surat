package models

import "time"

// OTP maps to PostgreSQL table otp.
type OTP struct {
	ID        uint      `gorm:"primaryKey;column:id_otp" json:"id"`
	UserID    uint      `gorm:"column:id_user;not null" json:"user_id"`
	KodeOTP   string    `gorm:"column:kode_otp;not null" json:"kode_otp"`
	ExpiresAt time.Time `gorm:"column:expires_at;not null" json:"expires_at"`
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`
	IsUsed    bool      `gorm:"column:is_used;default:false" json:"is_used"`

	User User `gorm:"foreignKey:UserID;references:ID" json:"user,omitempty"`
}

func (OTP) TableName() string {
	return "otp"
}
