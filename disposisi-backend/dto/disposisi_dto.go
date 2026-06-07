package dto

import "time"

type CreateDisposisiRequest struct {
	SuratMasukID         uint   `json:"surat_masuk_id" binding:"required"`
	TujuanIDs            []uint `json:"tujuan_ids" binding:"required,min=1"`
	Catatan              string `json:"catatan"`
	TanggapanSaran       string `json:"tanggapan_saran"`
	ProsesLanjut         string `json:"proses_lanjut"`
	KoordinasiKonfirmasi string `json:"koordinasi_konfirmasi"`
	BatasWaktu           string `json:"batas_waktu"` // YYYY-MM-DD, stored in proses_lanjut prefix batas:
	Sifat                string `json:"sifat"`       // segera | rahasia | sangat_rahasia (optional)
}

type ApproveDisposisiRequest struct {
	DisposisiID uint   `json:"disposisi_id" binding:"required"`
	IsApproved  bool   `json:"is_approved"`
	Catatan     string `json:"catatan"`
}

type DisposisiFilter struct {
	Status             string
	VerificationStatus string
	Search             string
	TanggalAwal        string
	TanggalAkhir       string
}

type DisposisiTujuanResponse struct {
	ID   uint   `json:"id"`
	Nama string `json:"nama"`
}

type DisposisiResponse struct {
	ID                 uint                    `json:"id"`
	SuratID            uint                    `json:"surat_id"`
	SuratNo            string                  `json:"surat_no"`
	Perihal            string                  `json:"perihal"`
	Tujuan             DisposisiTujuanResponse `json:"tujuan"`
	Status             string                  `json:"status"`
	VerificationStatus string                  `json:"verification_status"`
	Catatan            string                  `json:"catatan,omitempty"`
	PreviewURL         string                  `json:"preview_url"`
	BatasWaktu         string                  `json:"batas_waktu,omitempty"`
	CreatedAt          time.Time               `json:"created_at"`
}

type CreateDisposisiResult struct {
	Created int                    `json:"created"`
	Items   []DisposisiResponse    `json:"items"`
}
