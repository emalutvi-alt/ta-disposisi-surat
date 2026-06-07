package dto

import "time"

// CreateSuratMasukRequest metadata for multipart create (file handled separately).
type CreateSuratMasukRequest struct {
	NoSurat      string `form:"no_surat" binding:"required"`
	PerihalSurat string `form:"perihal_surat" binding:"required"`
	AsalSurat    string `form:"asal_surat" binding:"required"`
	TanggalSurat string `form:"tanggal_surat" binding:"required"` // YYYY-MM-DD
}

// UpdateSuratMasukRequest for PUT (optional file re-upload).
type UpdateSuratMasukRequest struct {
	NoSurat      string `form:"no_surat"`
	PerihalSurat string `form:"perihal_surat"`
	AsalSurat    string `form:"asal_surat"`
	TanggalSurat string `form:"tanggal_surat"`
}

// VerifikasiSuratMasukRequest for Kepsek approval.
// When approved with tujuan_ids, disposisi rows are created in the same flow.
type VerifikasiSuratMasukRequest struct {
	IsApproved           bool   `json:"is_approved"`
	Catatan              string `json:"catatan"`
	TujuanIDs            []uint `json:"tujuan_ids"`
	TanggapanSaran       string `json:"tanggapan_saran"`
	ProsesLanjut         string `json:"proses_lanjut"`
	KoordinasiKonfirmasi string `json:"koordinasi_konfirmasi"`
}

// SuratMasukFilter berisi filter untuk query list surat masuk.
type SuratMasukFilter struct {
	Status       string
	TanggalAwal  string
	TanggalAkhir string
	Search       string
	ArsipOnly    bool   // ← NEW: true = hanya arsip
}

// PDFPageDTO merepresentasikan satu halaman preview PDF untuk Flutter.
type PDFPageDTO struct {
	PageNumber int    `json:"page_number"`
	ImageURL   string `json:"image_url"`
}

// SuratMasukResponse — DIPERBARUI dengan fields halaman
type SuratMasukResponse struct {
    ID               uint         `json:"id"`
    NoSurat          string       `json:"no_surat"`
    Perihal          string       `json:"perihal"`
    AsalSurat        string       `json:"asal_surat"`
    Status           string       `json:"status"`
    StatusVerifikasi string       `json:"status_verifikasi,omitempty"`
    StatusAlur       string       `json:"status_alur,omitempty"`
    FileURL          string       `json:"file_url"`
    PreviewURL       string       `json:"preview_url"`    // halaman pertama (compat)
    TotalPages       int          `json:"total_pages"`    // ← BARU
    Pages            []PDFPageDTO `json:"pages"`          // ← BARU: SEMUA halaman
    CreatedAt        time.Time    `json:"created_at"`
    IsArsip          bool         `json:"is_arsip"`       // ← BARU
}
