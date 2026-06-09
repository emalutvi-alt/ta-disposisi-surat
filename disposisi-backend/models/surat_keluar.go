package models

import "time"

// SuratKeluar maps to PostgreSQL table surat_keluar.
type SuratKeluar struct {
	ID                uint       `gorm:"primaryKey;column:id_surat_keluar" json:"id"`
	KodeSurat         int        `gorm:"column:kode_surat;not null" json:"kode_surat"`
	NoSurat           string     `gorm:"column:no_surat;not null" json:"no_surat"`
	Perihal           string     `gorm:"column:perihal;not null" json:"perihal"`
	Catatan           *string    `gorm:"column:catatan" json:"catatan,omitempty"`
	TanggalSurat      time.Time  `gorm:"column:tanggal_surat;type:date;not null" json:"tanggal_surat"`
	FilePDF           *string    `gorm:"column:file_pdf" json:"file_pdf,omitempty"`
	FilePreview       *string    `gorm:"column:file_preview" json:"file_preview,omitempty"`
	StatusVerifikasi  string     `gorm:"column:status_verifikasi;default:menunggu" json:"status_verifikasi"`
	UserVerifikasi    *uint      `gorm:"column:user_verifikasi" json:"user_verifikasi,omitempty"`
	TanggalVerifikasi *time.Time `gorm:"column:tanggal_verifikasi" json:"tanggal_verifikasi,omitempty"`
	Tujuan            *string    `gorm:"column:tujuan" json:"tujuan,omitempty"`
	CatatanVerifikasi *string    `gorm:"column:catatan_verifikasi" json:"catatan_verifikasi,omitempty"`
	CreatedAt         time.Time  `gorm:"column:created_at" json:"created_at"`
	UpdatedAt         time.Time  `gorm:"column:updated_at" json:"updated_at"`
	StatusAlur        string     `gorm:"column:status_alur;default:diterima_tu" json:"status_alur"`
	RiwayatTU         bool       `gorm:"column:riwayat_tu;default:false" json:"riwayat_tu"`

	Distribusis []DistribusiSK `gorm:"foreignKey:SuratKeluarID;references:ID" json:"distribusis,omitempty"`
}

func (SuratKeluar) TableName() string {
	return "surat_keluar"
}
