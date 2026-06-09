package dto

import "time"

type CreateSuratKeluarRequest struct {
	KodeSurat    int    `form:"kode_surat" binding:"required"`
	NoSurat      string `form:"no_surat" binding:"required,max=50"`
	Perihal      string `form:"perihal" binding:"required"`
	Catatan      string `form:"catatan"`
	TanggalSurat string `form:"tanggal_surat" binding:"required"`
	Tujuan       string `form:"tujuan"`
}

type UpdateSuratKeluarRequest struct {
	KodeSurat    int    `form:"kode_surat"`
	NoSurat      string `form:"no_surat"`
	Perihal      string `form:"perihal"`
	Catatan      string `form:"catatan"`
	TanggalSurat string `form:"tanggal_surat"`
	Tujuan       string `form:"tujuan"`
}

type VerifikasiSuratKeluarRequest struct {
	IsApproved bool   `json:"is_approved"`
	Catatan    string `json:"catatan"`
}

type KonfirmasiTUSuratKeluarRequest struct{}

type DistribusiSuratKeluarRequest struct {
	UserIDs []uint `json:"user_ids" binding:"required,min=1"`
	Catatan string `json:"catatan"`
}

type SuratKeluarFilter struct {
	Status       string
	TanggalAwal  string
	TanggalAkhir string
	Search       string
}

type SuratKeluarResponse struct {
	ID               uint         `json:"id"`
	KodeSurat        int          `json:"kode_surat"`
	NoSurat          string       `json:"no_surat"`
	Perihal          string       `json:"perihal"`
	Tujuan           string       `json:"tujuan,omitempty"`
	Status           string       `json:"status"`
	StatusVerifikasi string       `json:"status_verifikasi,omitempty"`
	StatusAlur       string       `json:"status_alur,omitempty"`
	FileURL          string       `json:"file_url,omitempty"`
	PreviewURL       string       `json:"preview_url"`
	CreatedAt        time.Time    `json:"created_at"`
	TotalPages       int          `json:"total_pages"`
	Pages            []PDFPageDTO `json:"pages"`
}
