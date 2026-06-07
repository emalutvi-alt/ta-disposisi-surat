package dto

// --- Login (Phase 1) ---

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type LoginResponseData struct {
	Token string        `json:"token"`
	User  LoginUserData `json:"user"`
}

type LoginUserData struct {
	ID    uint   `json:"id"`
	Nama  string `json:"nama"`
	Email string `json:"email"`
	Role  string `json:"role"`
}

// --- Forgot / OTP ---

type EmailRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type VerifyOTPRequest struct {
	Email string `json:"email" binding:"required,email"`
	OTP   string `json:"otp" binding:"required,len=6"`
}

type ResetPasswordRequest struct {
	Email           string `json:"email" binding:"required,email"`
	ResetToken      string `json:"reset_token"`
	NewPassword     string `json:"new_password" binding:"required,min=8"`
	ConfirmPassword string `json:"confirm_password" binding:"required,min=8"`
}

// --- Authenticated ---

type ChangePasswordRequest struct {
	OldPassword     string `json:"old_password" binding:"required"`
	NewPassword     string `json:"new_password" binding:"required,min=8"`
	ConfirmPassword string `json:"confirm_password" binding:"required,min=8"`
}

type ProfileData struct {
	ID      uint   `json:"id"`
	Nama    string `json:"nama"`
	Email   string `json:"email"`
	Role    string `json:"role"`
	Jabatan string `json:"jabatan"`
}

// VerifyOTPResponseData returned after successful OTP verification.
type VerifyOTPResponseData struct {
	ResetToken string `json:"reset_token"`
}

// MessageData optional payload for simple success messages.
type MessageData struct {
	Message string `json:"message,omitempty"`
}
