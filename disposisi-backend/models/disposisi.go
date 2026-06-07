package models

import "time"

// Disposisi maps to PostgreSQL table disposisi.
type Disposisi struct {
	ID                   uint       `gorm:"primaryKey;column:id_disposisi" json:"id"`
	Catatan              *string    `gorm:"column:catatan_kepsek" json:"catatan,omitempty"`
	TanggapanSaran       *string    `gorm:"column:tanggapan_saran" json:"tanggapan_saran,omitempty"`
	ProsesLanjut         *string    `gorm:"column:proses_lanjut" json:"proses_lanjut,omitempty"`
	KoordinasiKonfirmasi *string    `gorm:"column:koordinasi_konfirmasi" json:"koordinasi_konfirmasi,omitempty"`
	SuratMasukID         uint       `gorm:"column:id_surat_masuk;not null" json:"id_surat_masuk"`
	KepsekID             uint       `gorm:"column:id_kepsek;not null" json:"id_kepsek"`
	PenerimaID           uint       `gorm:"column:id_penerima;not null" json:"id_penerima"`
	JabatanPenerimaID    *uint      `gorm:"column:id_jabatan_penerima" json:"id_jabatan_penerima,omitempty"`
	TanggalDisposisi     time.Time  `gorm:"column:tanggal_disposisi" json:"tanggal_disposisi"`
	StatusDisposisi      string     `gorm:"column:status_disposisi;default:belum_dibaca" json:"status_disposisi"`
	StatusApproval       string     `gorm:"column:status_approval;default:menunggu" json:"status_approval"`
	ApprovalAt           *time.Time `gorm:"column:approval_at" json:"approval_at,omitempty"`

	SuratMasuk SuratMasuk `gorm:"foreignKey:SuratMasukID;references:ID" json:"surat_masuk,omitempty"`
	Kepsek     User       `gorm:"foreignKey:KepsekID;references:ID" json:"kepsek,omitempty"`
	Penerima   User       `gorm:"foreignKey:PenerimaID;references:ID" json:"penerima,omitempty"`
}

func (Disposisi) TableName() string {
	return "disposisi"
}
