package services

import (
	"github.com/fiorelln/disposisi/config"
	"github.com/fiorelln/disposisi/helpers"
	"github.com/fiorelln/disposisi/repositories"
	"gorm.io/gorm"
)

// Container wires all service dependencies (dependency injection root).
type Container struct {
	Auth         *AuthService
	SuratMasuk   *SuratMasukService
	SuratKeluar  *SuratKeluarService
	Disposisi    *DisposisiService
	Notification *NotificationService
	Log          *LogService
	Dashboard    *DashboardService
	User         *UserService
	Unified      *UnifiedService
}

// NewContainer builds service layer from repositories.
func NewContainer(db *gorm.DB) *Container {
	userRepo := repositories.NewUserRepository(db)
	otpRepo := repositories.NewOTPRepository(db)
	mail := helpers.NewSMTPEmailSender(
		config.Cfg.SMTPHost,
		config.Cfg.SMTPPort,
		config.Cfg.SMTPEmail,
		config.Cfg.SMTPPassword,
		config.Cfg.SMTPFromName,
	)
	blacklist := helpers.NewNoopTokenBlacklist()

	suratMasukRepo := repositories.NewSuratMasukRepository(db)
	suratKeluarRepo := repositories.NewSuratKeluarRepository(db)
	distribusiSKRepo := repositories.NewDistribusiSKRepository(db)
	distribusiSMRepo := repositories.NewDistribusiSMRepository(db)
	disposisiRepo := repositories.NewDisposisiRepository(db)
	logDistribusiRepo := repositories.NewLogDistribusiRepository(db)
	notificationRepo := repositories.NewNotificationRepository(db)
	logRepo := repositories.NewLogRepository(db)
	dashboardRepo := repositories.NewDashboardRepository(db)
	pdfPreviewRepo := repositories.NewPDFPreviewRepository(db)
	pdfPreviewSvc := NewPDFPreviewService(pdfPreviewRepo)

	logSvc := NewLogService(logRepo, logDistribusiRepo)
	notifSvc := NewNotificationService(notificationRepo)

	disposisiSvc := NewDisposisiService(
		db,
		disposisiRepo,
		distribusiSMRepo,
		suratMasukRepo,
		userRepo,
		logSvc,
		notifSvc,
	)

	suratMasukSvc := NewSuratMasukService(
		suratMasukRepo, userRepo, logSvc, notifSvc, disposisiSvc,
		pdfPreviewSvc,
	)
	suratKeluarSvc := NewSuratKeluarService(
		suratKeluarRepo, distribusiSKRepo, userRepo, logSvc, notifSvc,
		pdfPreviewSvc,
	)

	// ← UPDATED: Pass db ke UserService untuk transaction support -> Removed db parameter to match userSvc constructor
	userSvc := NewUserService(userRepo)

	unifiedSvc := NewUnifiedService(
		db,
		suratMasukRepo,
		suratKeluarRepo,
		disposisiRepo,
		userRepo,
		notifSvc,
		logSvc,
	)

	return &Container{
		Auth:         NewAuthService(userRepo, otpRepo, mail, blacklist, logSvc),
		SuratMasuk:   suratMasukSvc,
		SuratKeluar:  suratKeluarSvc,
		Disposisi:    disposisiSvc,
		Notification: notifSvc,
		Log:          logSvc,
		Dashboard:    NewDashboardService(dashboardRepo, notifSvc),
		User:         userSvc,
		Unified:      unifiedSvc,
	}
}
