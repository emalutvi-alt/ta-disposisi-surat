package models

import "time"

// Notifikasi maps to PostgreSQL table notifikasi.
type Notifikasi struct {
	ID             uint       `gorm:"primaryKey;column:id_notifikasi" json:"id"`
	PenerimaID     uint       `gorm:"column:id_penerima;not null" json:"id_penerima"`
	PengirimID     *uint      `gorm:"column:id_pengirim" json:"id_pengirim,omitempty"`
	Jenis          *string    `gorm:"column:jenis" json:"jenis,omitempty"`
	Judul          string     `gorm:"column:judul;not null" json:"judul"`
	Pesan          *string    `gorm:"column:pesan" json:"pesan,omitempty"`
	IsRead         bool       `gorm:"column:is_read;default:false" json:"is_read"`
	WaktuBaca      *time.Time `gorm:"column:waktu_baca" json:"waktu_baca,omitempty"`
	CreatedAt      time.Time  `gorm:"column:created_at" json:"created_at"`
	LinkURL        *string    `gorm:"column:link_url" json:"link_url,omitempty"`
	TipeReferensi  *string    `gorm:"column:tipe_referensi" json:"tipe_referensi,omitempty"`

	Penerima User  `gorm:"foreignKey:PenerimaID;references:ID" json:"penerima,omitempty"`
	Pengirim *User `gorm:"foreignKey:PengirimID;references:ID" json:"pengirim,omitempty"`
}

func (Notifikasi) TableName() string {
	return "notifikasi"
}
