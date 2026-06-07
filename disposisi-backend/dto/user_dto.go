package dto

// UserBriefResponse is used for disposisi target picker (Flutter/Kepsek).
type UserBriefResponse struct {
	ID      uint   `json:"id"`
	Nama    string `json:"nama"`
	Email   string `json:"email"`
	Jabatan string `json:"jabatan"`
	Role    string `json:"role"`
}
