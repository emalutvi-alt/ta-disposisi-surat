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
		authorized.PUT("/surat-masuk/:id", suratMasukCtrl.Update)
		authorized.DELETE("/surat-masuk/:id", suratMasukCtrl.Delete)
		authorized.POST("/surat-masuk/:id/verifikasi", suratMasukCtrl.Verifikasi)

		// Unified Disposisi Surat Masuk (Kepsek)
		unifiedCtrl := controllers.NewUnifiedController(container.Unified)
		authorized.POST("/surat-masuk/:id/disposisi", unifiedCtrl.ProcessSuratMasukDisposisi)

		// Surat Keluar
		suratKeluarCtrl := controllers.NewSuratKeluarController(container.SuratKeluar)
		authorized.GET("/surat-keluar", suratKeluarCtrl.List)
		authorized.GET("/surat-keluar/:id", suratKeluarCtrl.GetByID)
		authorized.POST("/surat-keluar", suratKeluarCtrl.Create)
		authorized.PUT("/surat-keluar/:id", suratKeluarCtrl.Update)
		authorized.DELETE("/surat-keluar/:id", suratKeluarCtrl.Delete)
		authorized.POST("/surat-keluar/:id/verifikasi", suratKeluarCtrl.Verifikasi)

		// Unified Verifikasi Surat Keluar (Kepsek)
		authorized.POST("/surat-keluar/:id/verifikasi-unified", unifiedCtrl.ProcessSuratKeluarVerifikasi)

		// User - Mark surat dibaca
		authorized.PUT("/surat/:id/dibaca", unifiedCtrl.MarkSuratAsRead)

		// Disposisi
		disposisiCtrl := controllers.NewDisposisiController(container.Disposisi)
		authorized.GET("/disposisi", disposisiCtrl.List)
		authorized.GET("/disposisi/:id", disposisiCtrl.ListBySurat)
		authorized.POST("/disposisi", disposisiCtrl.Create)
		authorized.POST("/disposisi/:id/approve", disposisiCtrl.Approve)
		authorized.POST("/disposisi/:id/selesai", disposisiCtrl.MarkSelesai)

		// Distribusi
		authorized.GET("/distribusi", disposisiCtrl.ListBySurat)
		authorized.POST("/distribusi", disposisiCtrl.Create)
		authorized.PUT("/distribusi/:id", disposisiCtrl.Approve)

		// Dashboard
		dashboardCtrl := controllers.NewDashboardController(container.Dashboard)
		authorized.GET("/dashboard", dashboardCtrl.Stats)

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
		authorized.GET("/download/:filename", downloadCtrl.Download)
	}
}