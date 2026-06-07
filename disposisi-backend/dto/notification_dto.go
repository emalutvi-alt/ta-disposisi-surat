package dto

import "time"

type NotificationListQuery struct {
	Page       int
	Limit      int
	UnreadOnly bool
	Type       string
}

type NotificationResponse struct {
	ID          uint      `json:"id"`
	Title       string    `json:"title"`
	Message     string    `json:"message"`
	Type        string    `json:"type"`
	IsRead      bool      `json:"is_read"`
	ReferenceID uint      `json:"reference_id"`
	CreatedAt   time.Time `json:"created_at"`
}

type NotificationListData struct {
	Items        []NotificationResponse `json:"items"`
	Page         int                    `json:"page"`
	Limit        int                    `json:"limit"`
	Total        int64                  `json:"total"`
	UnreadCount  int64                  `json:"unread_count"`
}
