package routes

import (
	"github.com/fiorelln/disposisi/controllers"
	"github.com/fiorelln/disposisi/middlewares"
	"github.com/fiorelln/disposisi/services"
	"github.com/gin-gonic/gin"
)

func SetupRoutes(
	r *gin.Engine,
	container *services.Container,
) {

	// Scalar API docs
	r.StaticFile("/docs", "./docs/index.html")
	r.StaticFile("/openapi.yaml", "./openapi.yaml")

	// Public routes
	public := r.Group("")
	{
		authCtrl := controllers.NewAuthController(container.Auth)
		auth := public.Group("/api/auth")
		{
			auth.POST("/login", authCtrl.Login)
			auth.POST("/forgot-password", authCtrl.ForgotPassword)
			auth.POST("/resend-otp", authCtrl.ResendOTP)
			auth.POST("/verify-otp", authCtrl.VerifyOTP)
			auth.POST("/reset-password", authCtrl.ResetPassword)
		}
	}

	// Protected routes
	authorized := r.Group("/api")
	authorized.Use(middlewares.AuthMiddleware())
	{
		authCtrl := controllers.NewAuthController(container.Auth)
		authorized.GET("/profile", authCtrl.Profile)
		authorized.POST("/change-password", authCtrl.ChangePassword)
		authorized.POST("/logout", authCtrl.Logout)

		// Surat Masuk
		suratMasukCtrl := controllers.NewSuratMasukController(container.SuratMasuk)
		authorized.GET("/surat-masuk", suratMasukCtrl.List)
		authorized.GET("/surat-masuk/:id", suratMasukCtrl.GetByID)
		authorized.POST("/surat-masuk", suratMasukCtrl.Create)
		authorized.POST("/surat-masuk/:id/verifikasi", suratMasukCtrl.Verifikasi)
		authorized.POST("/surat-masuk/:id/konfirmasi-tu", suratMasukCtrl.KonfirmasiTU)
		authorized.POST("/surat-masuk/:id/kirim-ke-user", suratMasukCtrl.KirimKeUser)
		authorized.POST("/surat-masuk/:id/konfirmasi-penerimaan", suratMasukCtrl.KonfirmasiPenerimaan)
		authorized.GET("/surat-masuk/:id/pages", suratMasukCtrl.GetPages)

		// Unified Disposisi Surat Masuk (Kepsek)
		unifiedCtrl := controllers.NewUnifiedController(container.Unified)
		authorized.POST("/surat-masuk/:id/disposisi", unifiedCtrl.ProcessSuratMasukDisposisi)

		// Surat Keluar
		suratKeluarCtrl := controllers.NewSuratKeluarController(container.SuratKeluar)
		authorized.GET("/surat-keluar", suratKeluarCtrl.List)
		authorized.GET("/surat-keluar/:id", suratKeluarCtrl.GetByID)
		authorized.POST("/surat-keluar", suratKeluarCtrl.Create)
		authorized.POST("/surat-keluar/:id/verifikasi", suratKeluarCtrl.Verifikasi)
		authorized.POST("/surat-keluar/:id/konfirmasi-tu", suratKeluarCtrl.KonfirmasiTU)
		authorized.GET("/surat-keluar/:id/pages", suratKeluarCtrl.GetPages)

		// Unified Verifikasi Surat Keluar (Kepsek)
		authorized.POST("/surat-keluar/:id/verifikasi-unified", unifiedCtrl.ProcessSuratKeluarVerifikasi)

		// User - Mark surat dibaca
		authorized.PUT("/surat/:id/dibaca", unifiedCtrl.MarkSuratAsRead)

		// Dashboard
		dashboardCtrl := controllers.NewDashboardController(container.Dashboard)
		authorized.GET("/dashboard", dashboardCtrl.Stats)
		authorized.GET("/dashboard/aktif", dashboardCtrl.Aktif)
		authorized.GET("/riwayat", dashboardCtrl.Riwayat)

		// Notifications
		notifCtrl := controllers.NewNotificationController(container.Notification)
		authorized.GET("/notifications", notifCtrl.List)
		authorized.PUT("/notifications/:id/read", notifCtrl.MarkRead)
		authorized.PUT("/notifications/read-all", notifCtrl.MarkRead)

		// Users
		userCtrl := controllers.NewUserController(container.User)
		authorized.GET("/users", userCtrl.ListDisposisiTargets)
		authorized.GET("/users/disposisi-targets", userCtrl.ListDisposisiTargets)

		// Logs
		logCtrl := controllers.NewLogController(container.Log)
		authorized.GET("/logs", logCtrl.ListAudit)
		authorized.GET("/logs/audit", logCtrl.ListAudit)

		// Download
		downloadCtrl := controllers.NewDownloadController(container.Log)
		authorized.GET("/surat-masuk/:id/preview/:page/download", downloadCtrl.DownloadSuratMasukPreview)
		authorized.GET("/surat-keluar/:id/preview/:page/download", downloadCtrl.DownloadSuratKeluarPreview)
	}
}
