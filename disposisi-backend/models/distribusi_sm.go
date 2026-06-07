package models

import "time"

// DistribusiSM maps to PostgreSQL table distribusi_sm (tracking per penerima disposisi).
type DistribusiSM struct {
	ID          uint       `gorm:"primaryKey;column:id_penerima_disposisi" json:"id"`
	DisposisiID uint       `gorm:"column:id_disposisi;not null" json:"id_disposisi"`
	UserID      *uint      `gorm:"column:id_user" json:"id_user,omitempty"`
	JabatanID   *uint      `gorm:"column:id_jabatan" json:"id_jabatan,omitempty"`
	ReadAt      *time.Time `gorm:"column:read_at" json:"read_at,omitempty"`
	CreatedAt   time.Time  `gorm:"column:created_at" json:"created_at"`
	Status      string     `gorm:"column:status;default:belum_dibaca" json:"status"`

	Disposisi Disposisi `gorm:"foreignKey:DisposisiID;references:ID" json:"disposisi,omitempty"`
	User      *User     `gorm:"foreignKey:UserID;references:ID" json:"user,omitempty"`
}

func (DistribusiSM) TableName() string {
	return "distribusi_sm"
}
