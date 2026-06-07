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
