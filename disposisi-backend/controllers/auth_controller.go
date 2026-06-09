package controllers

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/services"
	"github.com/fiorelln/disposisi/utils"
	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
	"github.com/golang-jwt/jwt/v5"
)

// AuthController handles HTTP auth endpoints (validation + response only).
type AuthController struct {
	auth *services.AuthService
}

func NewAuthController(auth *services.AuthService) *AuthController {
	return &AuthController{auth: auth}
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN — ERROR HANDLING DIPISAH PER FIELD (EMAIL vs PASSWORD)
// ─────────────────────────────────────────────────────────────────────────────

// Login POST /auth/login
// Response error format: {"email": "...", "password": "..."} — masing-masing di bawah field-nya
func (h *AuthController) Login(c *gin.Context) {
	var req dto.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		// Format error validasi ke map terpisah per field
		fieldErrors := formatValidationErrors(err)
		if len(fieldErrors) > 0 {
			utils.ErrorBadRequest(c, "validasi gagal", fieldErrors)
		} else {
			utils.ErrorBadRequest(c, "format JSON tidak valid", nil)
		}
		return
	}

	// Validasi tambahan: email format manual (lebih spesifik dari Gin validator)
	emailErrors := make(map[string]string)
	if !containsAt(req.Email) {
		emailErrors["email"] = "Email wajib mengandung tanda @ (contoh: nama@email.com)"
	}
	if len(emailErrors) > 0 {
		utils.ErrorBadRequest(c, "validasi gagal", emailErrors)
		return
	}

	data, err := h.auth.Login(req.Email, req.Password)
	if err != nil {
		h.handleLoginError(c, err, req.Email)
		return
	}

	utils.SuccessOK(c, "login berhasil", data)
}

// handleLoginError memisahkan error antara email salah vs password salah
// agar Flutter bisa menampilkan warning di bawah field yang bersangkutan
func (h *AuthController) handleLoginError(c *gin.Context, err error, attemptedEmail string) {
	switch {
	case errors.Is(err, services.ErrInvalidEmail):
		// Email format tidak valid — tampilkan di bawah input email
		utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
			"email": "Format email tidak valid. Pastikan ada @ dan domain (contoh: nama@email.com)",
		})

	case errors.Is(err, services.ErrInvalidCredentials):
		// Periksa apakah email ada di database — jika tidak, error di email
		// Jika email ada tapi password salah, error di password
		emailExists, _ := h.auth.CheckEmailExists(attemptedEmail)
		if !emailExists {
			utils.ErrorBadRequest(c, "Email tidak ditemukan", nil)
		} else {
			utils.ErrorBadRequest(c, "Password salah", nil)
		}

	default:
		utils.ErrorInternal(c, "Terjadi kesalahan pada server")
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD
// ─────────────────────────────────────────────────────────────────────────────

func (h *AuthController) ForgotPassword(c *gin.Context) {
	var req dto.EmailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		fieldErrors := formatValidationErrors(err)
		if len(fieldErrors) > 0 {
			utils.ErrorBadRequest(c, "validasi gagal", fieldErrors)
		} else {
			utils.ErrorBadRequest(c, "format JSON tidak valid", nil)
		}
		return
	}

	// Validasi email harus ada @
	if !containsAt(req.Email) {
		utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
			"email": "Email wajib mengandung tanda @ (contoh: nama@email.com)",
		})
		return
	}

	err := h.auth.ForgotPassword(req.Email)
	if err != nil {
		if errors.Is(err, services.ErrOTPRateLimit) {
			utils.ErrorTooManyRequests(c, err.Error())
			return
		}
		if errors.Is(err, services.ErrEmailSendFailed) {
			utils.ErrorInternal(c, err.Error())
			return
		}
		h.handleAuthError(c, err)
		return
	}

	utils.SuccessOK(c, "OTP berhasil dikirim", nil)
}

// ─────────────────────────────────────────────────────────────────────────────
// RESEND OTP
// ─────────────────────────────────────────────────────────────────────────────

func (h *AuthController) ResendOTP(c *gin.Context) {
	var req dto.EmailRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		fieldErrors := formatValidationErrors(err)
		if len(fieldErrors) > 0 {
			utils.ErrorBadRequest(c, "validasi gagal", fieldErrors)
		} else {
			utils.ErrorBadRequest(c, "format JSON tidak valid", nil)
		}
		return
	}

	if !containsAt(req.Email) {
		utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
			"email": "Email wajib mengandung tanda @ (contoh: nama@email.com)",
		})
		return
	}

	err := h.auth.ResendOTP(req.Email)
	if err != nil {
		if errors.Is(err, services.ErrResendCooldown) {
			utils.ErrorTooManyRequests(c, err.Error())
			return
		}
		if errors.Is(err, services.ErrEmailSendFailed) {
			utils.ErrorInternal(c, err.Error())
			return
		}
		h.handleAuthError(c, err)
		return
	}

	utils.SuccessOK(c, "OTP berhasil dikirim ulang", nil)
}

// ─────────────────────────────────────────────────────────────────────────────
// VERIFY OTP
// ─────────────────────────────────────────────────────────────────────────────

func (h *AuthController) VerifyOTP(c *gin.Context) {
	var req dto.VerifyOTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		fieldErrors := formatValidationErrors(err)
		if len(fieldErrors) > 0 {
			utils.ErrorBadRequest(c, "validasi gagal", fieldErrors)
		} else {
			utils.ErrorBadRequest(c, "format JSON tidak valid", nil)
		}
		return
	}

	if !containsAt(req.Email) {
		utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
			"email": "Email wajib mengandung tanda @ (contoh: nama@email.com)",
		})
		return
	}

	data, err := h.auth.VerifyOTP(req.Email, req.OTP)
	if err != nil {
		if errors.Is(err, services.ErrOTPInvalid) || errors.Is(err, services.ErrOTPExpired) {
			utils.ErrorBadRequest(c, err.Error(), map[string]string{
				"otp": err.Error(),
			})
			return
		}
		h.handleAuthError(c, err)
		return
	}

	utils.SuccessOK(c, "OTP valid", data)
}

// ─────────────────────────────────────────────────────────────────────────────
// RESET PASSWORD
// ─────────────────────────────────────────────────────────────────────────────

func (h *AuthController) ResetPassword(c *gin.Context) {
	var req dto.ResetPasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		fieldErrors := formatValidationErrors(err)
		if len(fieldErrors) > 0 {
			utils.ErrorBadRequest(c, "validasi gagal", fieldErrors)
		} else {
			utils.ErrorBadRequest(c, "format JSON tidak valid", nil)
		}
		return
	}

	if !containsAt(req.Email) {
		utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
			"email": "Email wajib mengandung tanda @ (contoh: nama@email.com)",
		})
		return
	}

	err := h.auth.ResetPassword(req.Email, req.ResetToken, req.NewPassword, req.ConfirmPassword)
	if err != nil {
		if errors.Is(err, services.ErrPasswordMismatch) {
			utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
				"confirm_password": err.Error(),
			})
			return
		}
		if errors.Is(err, services.ErrInvalidPassword) {
			utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
				"new_password": err.Error(),
			})
			return
		}
		if errors.Is(err, services.ErrOTPNotVerified) {
			utils.ErrorBadRequest(c, err.Error(), map[string]string{
				"otp": err.Error(),
			})
			return
		}
		h.handleAuthError(c, err)
		return
	}

	utils.SuccessOK(c, "Password berhasil direset", nil)
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE
// ─────────────────────────────────────────────────────────────────────────────

func (h *AuthController) Profile(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}

	data, err := h.auth.Profile(userID)
	if err != nil {
		h.handleProtectedError(c, err)
		return
	}

	utils.SuccessOK(c, "Data berhasil diambil", data)
}

// ─────────────────────────────────────────────────────────────────────────────
// CHANGE PASSWORD
// ─────────────────────────────────────────────────────────────────────────────

func (h *AuthController) ChangePassword(c *gin.Context) {
	userID, err := utils.GetUserID(c)
	if err != nil {
		utils.ErrorUnauthorized(c, "Akses tidak sah")
		return
	}

	var req dto.ChangePasswordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		fieldErrors := formatValidationErrors(err)
		if len(fieldErrors) > 0 {
			utils.ErrorBadRequest(c, "validasi gagal", fieldErrors)
		} else {
			utils.ErrorBadRequest(c, "format JSON tidak valid", nil)
		}
		return
	}

	err = h.auth.ChangePassword(userID, req.OldPassword, req.NewPassword, req.ConfirmPassword)
	if err != nil {
		if errors.Is(err, services.ErrPasswordMismatch) {
			utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
				"confirm_password": err.Error(),
			})
			return
		}
		if errors.Is(err, services.ErrInvalidPassword) {
			utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
				"new_password": err.Error(),
			})
			return
		}
		if errors.Is(err, services.ErrOldPasswordWrong) {
			utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
				"old_password": err.Error(),
			})
			return
		}
		h.handleAuthError(c, err)
		return
	}

	utils.SuccessOK(c, "Password berhasil diubah", nil)
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGOUT
// ─────────────────────────────────────────────────────────────────────────────

func (h *AuthController) Logout(c *gin.Context) {
	tokenString := extractBearerToken(c)
	var exp time.Time
	if tokenString != "" {
		if t, err := parseTokenExpiry(tokenString); err == nil {
			exp = t
		}
	}

	userID, _ := utils.GetUserID(c)
	_ = h.auth.Logout(userID, tokenString, exp)
	utils.SuccessOK(c, "logout berhasil", nil)
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR HANDLERS
// ─────────────────────────────────────────────────────────────────────────────

func (h *AuthController) handleAuthError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrInvalidEmail):
		utils.ErrorBadRequest(c, "validasi gagal", map[string]string{
			"email": "Format email tidak valid. Pastikan ada @ dan domain (contoh: nama@email.com)",
		})
	case errors.Is(err, services.ErrInvalidCredentials):
		utils.ErrorUnauthorized(c, "Email atau kata sandi salah")
	default:
		utils.ErrorInternal(c, "Terjadi kesalahan pada server")
	}
}

func (h *AuthController) handleProtectedError(c *gin.Context, err error) {
	switch {
	case errors.Is(err, services.ErrUserNotFound):
		utils.ErrorUnauthorized(c, "Akses tidak sah")
	default:
		utils.ErrorInternal(c, "Terjadi kesalahan pada server")
	}
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS — VALIDATION & FORMATTING
// ─────────────────────────────────────────────────────────────────────────────

// formatValidationErrors mengubah error validator Go ke map[field]message dalam Bahasa Indonesia
// Hasil: {"email": "Email wajib diisi", "password": "Kata sandi wajib diisi"}
func formatValidationErrors(err error) map[string]string {
	errorsMap := make(map[string]string)

	var ve validator.ValidationErrors
	if errors.As(err, &ve) {
		for _, fe := range ve {
			field := strings.ToLower(fe.Field())
			tag := fe.Tag()

			switch tag {
			case "required":
				errorsMap[field] = fmt.Sprintf("%s wajib diisi", fieldNameID(field))
			case "email":
				// Error email tanpa @ — ditampilkan di bawah input email
				errorsMap[field] = "Format email tidak valid. Pastikan ada @ dan domain (contoh: nama@email.com)"
			case "min":
				errorsMap[field] = fmt.Sprintf("%s minimal %s karakter", fieldNameID(field), fe.Param())
			case "max":
				errorsMap[field] = fmt.Sprintf("%s maksimal %s karakter", fieldNameID(field), fe.Param())
			case "len":
				errorsMap[field] = fmt.Sprintf("%s harus %s karakter", fieldNameID(field), fe.Param())
			default:
				errorsMap[field] = fmt.Sprintf("%s tidak valid", fieldNameID(field))
			}
		}
		return errorsMap
	}

	// Bukan validation error (misal: JSON malformed)
	return nil
}

// fieldNameID mengubah nama field ke Bahasa Indonesia untuk pesan error
func fieldNameID(field string) string {
	switch field {
	case "email":
		return "Email"
	case "password":
		return "Kata sandi"
	case "new_password":
		return "Kata sandi baru"
	case "confirm_password":
		return "Konfirmasi kata sandi"
	case "old_password":
		return "Kata sandi lama"
	case "otp":
		return "Kode OTP"
	default:
		return strings.Title(field)
	}
}

// containsAt memeriksa apakah string mengandung tanda @
// Digunakan untuk deteksi email tanpa @ sebelum validasi regex
func containsAt(s string) bool {
	return strings.Contains(s, "@")
}

// ─────────────────────────────────────────────────────────────────────────────
// TOKEN HELPERS
// ─────────────────────────────────────────────────────────────────────────────

func extractBearerToken(c *gin.Context) string {
	auth := c.GetHeader("Authorization")
	parts := strings.SplitN(auth, " ", 2)
	if len(parts) == 2 && parts[0] == "Bearer" {
		return parts[1]
	}
	return ""
}

func parseTokenExpiry(tokenString string) (time.Time, error) {
	parser := jwt.NewParser()
	token, _, err := parser.ParseUnverified(tokenString, jwt.MapClaims{})
	if err != nil {
		return time.Time{}, err
	}
	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return time.Time{}, errors.New("invalid claims")
	}
	exp, ok := claims["exp"].(float64)
	if !ok {
		return time.Time{}, errors.New("no exp")
	}
	return time.Unix(int64(exp), 0), nil
}
