package models

import "time"

// DistribusiSK maps to PostgreSQL table distribusi_sk.
type DistribusiSK struct {
	ID             uint       `gorm:"primaryKey;column:id_distribusi" json:"id"`
	SuratKeluarID  uint       `gorm:"column:id_sk;not null" json:"id_sk"`
	UserID         uint       `gorm:"column:id_user;not null" json:"id_user"`
	Status         string     `gorm:"column:status;default:belum_dibaca" json:"status"`
	DistributeAt   time.Time  `gorm:"column:distribute_at" json:"distribute_at"`
	ReadAt         *time.Time `gorm:"column:read_at" json:"read_at,omitempty"`
	Catatan        *string    `gorm:"column:catatan" json:"catatan,omitempty"`

	SuratKeluar SuratKeluar `gorm:"foreignKey:SuratKeluarID;references:ID" json:"surat_keluar,omitempty"`
	User        User        `gorm:"foreignKey:UserID;references:ID" json:"user,omitempty"`
}

func (DistribusiSK) TableName() string {
	return "distribusi_sk"
}
