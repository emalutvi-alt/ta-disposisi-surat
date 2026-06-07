package models

import "time"

// LogDistribusi maps to PostgreSQL table log_distribusi (riwayat alur surat).
type LogDistribusi struct {
	ID           uint      `gorm:"primaryKey;column:id_riwayat" json:"id"`
	SuratMasukID *uint     `gorm:"column:id_sm" json:"id_sm,omitempty"`
	SuratKeluarID *uint    `gorm:"column:id_sk" json:"id_sk,omitempty"`
	StatusAsal   *string   `gorm:"column:status_asal" json:"status_asal,omitempty"`
	StatusTujuan *string   `gorm:"column:status_tujuan" json:"status_tujuan,omitempty"`
	UserID       *uint     `gorm:"column:id_user" json:"id_user,omitempty"`
	Catatan      *string   `gorm:"column:catatan" json:"catatan,omitempty"`
	CreatedAt    time.Time `gorm:"column:created_at" json:"created_at"`

	SuratMasuk  *SuratMasuk  `gorm:"foreignKey:SuratMasukID;references:ID" json:"surat_masuk,omitempty"`
	SuratKeluar *SuratKeluar `gorm:"foreignKey:SuratKeluarID;references:ID" json:"surat_keluar,omitempty"`
	User        *User        `gorm:"foreignKey:UserID;references:ID" json:"user,omitempty"`
}

func (LogDistribusi) TableName() string {
	return "log_distribusi"
}
