package services

import (
	"errors"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/helpers"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
	"gorm.io/gorm"
)

var (
	ErrInvalidEmail       = errors.New("format email tidak valid")
	ErrInvalidCredentials = errors.New("email atau kata sandi salah")
	ErrOTPRateLimit       = errors.New("limit pengiriman OTP terlampaui. Silakan coba beberapa saat lagi")
	ErrEmailSendFailed    = errors.New("gagal mengirim email OTP")
	ErrResendCooldown     = errors.New("tunggu beberapa saat sebelum mengirim ulang OTP")
	ErrOTPInvalid         = errors.New("kode OTP salah")
	ErrOTPExpired         = errors.New("kode OTP telah kedaluwarsa")
	ErrPasswordMismatch   = errors.New("konfirmasi kata sandi tidak cocok")
	ErrInvalidPassword     = errors.New("kata sandi harus minimal 8 karakter")
	ErrOTPNotVerified     = errors.New("OTP belum diverifikasi")
	ErrOldPasswordWrong   = errors.New("kata sandi lama salah")
	ErrUserNotFound       = errors.New("user tidak ditemukan")
)

type AuthService struct {
	users     *repositories.UserRepository
	otp       *repositories.OTPRepository
	mail      helpers.EmailSender
	blacklist helpers.TokenBlacklist
	logs      *LogService
}

func NewAuthService(
	users *repositories.UserRepository,
	otp *repositories.OTPRepository,
	mail helpers.EmailSender,
	blacklist helpers.TokenBlacklist,
	logs *LogService,
) *AuthService {
	return &AuthService{
		users:     users,
		otp:       otp,
		mail:      mail,
		blacklist: blacklist,
		logs:      logs,
	}
}

func getUserRole(user *models.User) string {
	level := utils.LevelUser
	if len(user.UserJabatans) > 0 {
		var primaryJabatan *models.UserJabatan
		for i := range user.UserJabatans {
			if user.UserJabatans[i].IsPrimary {
				primaryJabatan = &user.UserJabatans[i]
				break
			}
		}
		if primaryJabatan == nil {
			primaryJabatan = &user.UserJabatans[0]
		}
		level = utils.NormalizeLevelAkses(primaryJabatan.Jabatan.LevelAkses)
	}
	return utils.MapLevelToFlutter(level)
}

func getUserJabatan(user *models.User) string {
	jabatan := ""
	for _, uj := range user.UserJabatans {
		if uj.Jabatan.NamaJabatan != "" {
			jabatan = uj.Jabatan.NamaJabatan
			if uj.IsPrimary {
				break
			}
		}
	}
	return jabatan
}

func (s *AuthService) Login(email, password string) (*dto.LoginResponseData, error) {
	user, err := s.users.FindByEmail(email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrInvalidCredentials
		}
		return nil, err
	}

	if !helpers.CheckPassword(user.Password, password) {
		return nil, ErrInvalidCredentials
	}

	role := getUserRole(user)
	token, err := helpers.GenerateToken(helpers.TokenClaims{
		UserID: user.ID,
		Email:  user.Email,
		Role:   role,
	})
	if err != nil {
		return nil, err
	}

	s.logs.WriteAuditLog(AuditLogInput{
		UserID:   &user.ID,
		Action:   AuditLogin,
		Table:    "users",
		RecordID: &user.ID,
	})

	return &dto.LoginResponseData{
		Token: token,
		User: dto.LoginUserData{
			ID:    user.ID,
			Nama:  user.Name,
			Email: user.Email,
			Role:  role,
		},
	}, nil
}

func (s *AuthService) CheckEmailExists(email string) (bool, error) {
	_, err := s.users.FindByEmail(email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return false, nil
		}
		return false, err
	}
	return true, nil
}

func (s *AuthService) ForgotPassword(email string) error {
	user, err := s.users.FindByEmail(email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrUserNotFound
		}
		return err
	}

	since := time.Now().Add(-25 * time.Minute)
	count, err := s.otp.CountRecentByUser(user.ID, since)
	if err == nil && count >= 5 {
		return ErrOTPRateLimit
	}

	_ = s.otp.InvalidateActiveByUser(user.ID)

	otpCode, err := helpers.GenerateOTP()
	if err != nil {
		return err
	}

	expiresAt := time.Now().Add(2 * time.Minute)
	otp := &models.OTP{
		UserID:    user.ID,
		KodeOTP:   otpCode,
		ExpiresAt: expiresAt,
		CreatedAt: time.Now(),
		IsUsed:    false,
	}

	if err := s.otp.Create(otp); err != nil {
		return err
	}

	err = s.mail.SendOTP(user.Email, otpCode)
	if err != nil {
		_ = s.otp.Delete(otp.ID)
		return ErrEmailSendFailed
	}

	return nil
}

func (s *AuthService) ResendOTP(email string) error {
	user, err := s.users.FindByEmail(email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrUserNotFound
		}
		return err
	}

	latest, err := s.otp.FindLatestByUser(user.ID)
	if err == nil && latest != nil {
		if time.Since(latest.CreatedAt) < 1*time.Minute {
			return ErrResendCooldown
		}
	}

	since := time.Now().Add(-25 * time.Minute)
	count, err := s.otp.CountRecentByUser(user.ID, since)
	if err == nil && count >= 5 {
		return ErrOTPRateLimit
	}

	_ = s.otp.InvalidateActiveByUser(user.ID)

	otpCode, err := helpers.GenerateOTP()
	if err != nil {
		return err
	}

	expiresAt := time.Now().Add(2 * time.Minute)
	otp := &models.OTP{
		UserID:    user.ID,
		KodeOTP:   otpCode,
		ExpiresAt: expiresAt,
		CreatedAt: time.Now(),
		IsUsed:    false,
	}

	if err := s.otp.Create(otp); err != nil {
		return err
	}

	err = s.mail.SendOTP(user.Email, otpCode)
	if err != nil {
		_ = s.otp.Delete(otp.ID)
		return ErrEmailSendFailed
	}

	return nil
}

func (s *AuthService) VerifyOTP(email, inputOTP string) (*dto.VerifyOTPResponseData, error) {
	user, err := s.users.FindByEmail(email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}

	latest, err := s.otp.FindLatestByUser(user.ID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrOTPInvalid
		}
		return nil, err
	}

	if latest.IsUsed {
		return nil, ErrOTPInvalid
	}

	if latest.ExpiresAt.Before(time.Now()) {
		return nil, ErrOTPExpired
	}

	if latest.KodeOTP != inputOTP {
		return nil, ErrOTPInvalid
	}

	err = s.otp.MarkUsed(latest.ID)
	if err != nil {
		return nil, err
	}

	resetToken, err := helpers.GenerateResetToken(user.ID, email)
	if err != nil {
		return nil, err
	}

	return &dto.VerifyOTPResponseData{
		ResetToken: resetToken,
	}, nil
}

func (s *AuthService) ResetPassword(email, resetToken, newPassword, confirmPassword string) error {
	if newPassword != confirmPassword {
		return ErrPasswordMismatch
	}

	if len(newPassword) < 8 {
		return ErrInvalidPassword
	}

	userID, err := helpers.ValidateResetToken(resetToken, email)
	if err != nil {
		return ErrOTPNotVerified
	}

	since := time.Now().Add(-5 * time.Minute)
	_, err = s.otp.FindVerifiedWithin(userID, since)
	if err != nil {
		return ErrOTPNotVerified
	}

	hashed, err := helpers.HashPassword(newPassword)
	if err != nil {
		return err
	}

	err = s.users.UpdatePassword(userID, hashed)
	if err != nil {
		return err
	}

	_ = s.otp.InvalidateAllByUser(userID)

	s.logs.WriteAuditLog(AuditLogInput{
		UserID:   &userID,
		Action:   "reset_password",
		Table:    "users",
		RecordID: &userID,
	})

	return nil
}

func (s *AuthService) Profile(userID uint) (*dto.ProfileData, error) {
	user, err := s.users.FindByID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrUserNotFound
		}
		return nil, err
	}

	role := getUserRole(user)
	jabatan := getUserJabatan(user)

	return &dto.ProfileData{
		ID:      user.ID,
		Nama:    user.Name,
		Email:   user.Email,
		Role:    role,
		Jabatan: jabatan,
	}, nil
}

func (s *AuthService) ChangePassword(userID uint, oldPassword, newPassword, confirmPassword string) error {
	if newPassword != confirmPassword {
		return ErrPasswordMismatch
	}

	if len(newPassword) < 8 {
		return ErrInvalidPassword
	}

	user, err := s.users.FindByID(userID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrUserNotFound
		}
		return err
	}

	if !helpers.CheckPassword(user.Password, oldPassword) {
		return ErrOldPasswordWrong
	}

	hashed, err := helpers.HashPassword(newPassword)
	if err != nil {
		return err
	}

	err = s.users.UpdatePassword(userID, hashed)
	if err != nil {
		return err
	}

	s.logs.WriteAuditLog(AuditLogInput{
		UserID:   &userID,
		Action:   "change_password",
		Table:    "users",
		RecordID: &userID,
	})

	return nil
}

func (s *AuthService) Logout(userID uint, tokenString string, exp time.Time) error {
	_ = s.blacklist.Add(tokenString, exp)

	s.logs.WriteAuditLog(AuditLogInput{
		UserID:   &userID,
		Action:   AuditLogout,
		Table:    "users",
		RecordID: &userID,
	})

	return nil
}