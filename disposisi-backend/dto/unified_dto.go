package dto

import "time"

type UnifiedDisposisiRequest struct {
	Status               string   `json:"status" binding:"required"` // disetujui | ditolak
	Catatan              string   `json:"catatan"`
	Tujuan               []string `json:"tujuan"`
	TanggapanSaran       string   `json:"tanggapan_saran"`
	ProsesLanjut         string   `json:"proses_lanjut"`
	KoordinasiKonfirmasi string   `json:"koordinasi_konfirmasi"`
}

type UnifiedDisposisiResponse struct {
	IDSurat              uint      `json:"id_surat"`
	Status               string    `json:"status"`
	Catatan              string    `json:"catatan,omitempty"`
	Tujuan               []string  `json:"tujuan,omitempty"`
	TanggapanSaran       string    `json:"tanggapan_saran,omitempty"`
	ProsesLanjut         string    `json:"proses_lanjut,omitempty"`
	KoordinasiKonfirmasi string    `json:"koordinasi_konfirmasi,omitempty"`
	TanggalDisposisi     time.Time `json:"tanggal_disposisi"`
	DiteruskanKe         string    `json:"diteruskan_ke,omitempty"`
}
