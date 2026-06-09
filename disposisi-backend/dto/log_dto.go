package dto

import "time"

type AuditLogListQuery struct {
	Page   int
	Limit  int
	Search string
}

type AuditLogResponse struct {
	ID        uint      `json:"id"`
	UserID    *uint     `json:"user_id,omitempty"`
	Action    string    `json:"action"`
	Table     string    `json:"table,omitempty"`
	RecordID  *int      `json:"record_id,omitempty"`
	OldValue  string    `json:"old_value,omitempty"`
	NewValue  string    `json:"new_value,omitempty"`
	CreatedAt time.Time `json:"created_at"`
}

type AuditLogListData struct {
	Items []AuditLogResponse `json:"items"`
	Page  int                `json:"page"`
	Limit int                `json:"limit"`
	Total int64              `json:"total"`
}

type DashboardStatsResponse struct {
	TotalSuratMasuk     int64 `json:"total_surat_masuk"`
	TotalSuratKeluar    int64 `json:"total_surat_keluar"`
	TotalDisposisi      int64 `json:"total_disposisi"`
	UnreadNotifications int64 `json:"unread_notifications"`
	PendingApproval     int64 `json:"pending_approval"`
	SuratSelesai        int64 `json:"surat_selesai"`
}

type DashboardSuratItem struct {
	ID               uint      `json:"id"`
	JenisSurat       string    `json:"jenis_surat"`
	NoSurat          string    `json:"no_surat"`
	Perihal          string    `json:"perihal"`
	AsalSurat        string    `json:"asal_surat,omitempty"`
	Tujuan           string    `json:"tujuan,omitempty"`
	Status           string    `json:"status"`
	StatusVerifikasi string    `json:"status_verifikasi,omitempty"`
	StatusAlur       string    `json:"status_alur,omitempty"`
	TanggalSurat     string    `json:"tanggal_surat"`
	PreviewURL       string    `json:"preview_url,omitempty"`
	RoleRiwayat      string    `json:"role_riwayat,omitempty"`
	CreatedAt        time.Time `json:"created_at"`
}

type DashboardListData struct {
	Items []DashboardSuratItem `json:"items"`
	Total int                  `json:"total"`
}

type RiwayatFilterQuery struct {
	Filter  string
	Tanggal string
}
