package models

import "time"

// SuratMasuk maps to PostgreSQL table surat_masuk.
type SuratMasuk struct {
	ID                 uint       `gorm:"primaryKey;column:id_surat_masuk" json:"id"`
	NoSurat            string     `gorm:"column:no_surat;not null" json:"no_surat"`
	PerihalSurat       string     `gorm:"column:perihal_surat;not null" json:"perihal_surat"`
	AsalSurat          string     `gorm:"column:asal_surat;not null" json:"asal_surat"`
	TanggalSurat       time.Time  `gorm:"column:tanggal_surat;type:date;not null" json:"tanggal_surat"`
	FilePDF            *string    `gorm:"column:file_pdf" json:"file_pdf,omitempty"`
	FilePreview        *string    `gorm:"column:file_preview" json:"file_preview,omitempty"`
	TanggalDiterima    *time.Time `gorm:"column:tanggal_diterima;type:date" json:"tanggal_diterima,omitempty"`
	StatusVerifikasi   string     `gorm:"column:status_verifikasi;default:menunggu" json:"status_verifikasi"`
	UserVerifikasi     *uint      `gorm:"column:user_verifikasi" json:"user_verifikasi,omitempty"`
	TanggalVerifikasi  *time.Time `gorm:"column:tanggal_verifikasi" json:"tanggal_verifikasi,omitempty"`
	CatatanVerifikasi  *string    `gorm:"column:catatan_verifikasi" json:"catatan_verifikasi,omitempty"`
	CreatedAt          time.Time  `gorm:"column:created_at" json:"created_at"`
	DisposisiAktifID   *uint      `gorm:"column:id_disposisi_aktif" json:"id_disposisi_aktif,omitempty"`
	StatusAlur         string     `gorm:"column:status_alur;default:diterima_tu" json:"status_alur"`
	UpdatedAt          time.Time  `gorm:"column:updated_at" json:"updated_at"`
	IsArsip            bool       `gorm:"column:is_arsip;default:false" json:"is_arsip"` // ← NEW: Arsip flag

	Disposisis []Disposisi `gorm:"foreignKey:SuratMasukID;references:ID" json:"disposisis,omitempty"`
}

func (SuratMasuk) TableName() string {
	return "surat_masuk"
}