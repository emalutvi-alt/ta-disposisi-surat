package main

import (
	"log"

	"github.com/fiorelln/disposisi/config"
	"github.com/fiorelln/disposisi/helpers"
	"github.com/fiorelln/disposisi/routes"
	"github.com/fiorelln/disposisi/services"
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func main() {
	// 1. Load konfigurasi dari .env — FATAL jika JWT_SECRET kosong
	//    WARNING jika BASE_URL tidak diset (preview URL broken di mobile)
	config.LoadEnv()

	// 2. Koneksi PostgreSQL + safe migration (ADD COLUMN IF NOT EXISTS)
	config.ConnectDB()

	// 3. Pastikan PDF placeholder tersedia sebelum request pertama masuk.
	//    Jika AssignPDFPreview() dipanggil saat upload dan placeholder belum ada,
	//    surat masih bisa disimpan tapi preview akan error.
	if err := helpers.EnsureDefaultPDFPlaceholder(); err != nil {
		log.Printf("WARNING: gagal menyiapkan PDF placeholder: %v", err)
	}

	// 4. Dependency injection
	svc := services.NewContainer(config.DB)

	// 5. Gin router
	r := gin.Default()

	// 6. CORS — development: allow all; production: dari CORS_ORIGIN di .env
	//    Flutter Dio tidak terpengaruh CORS (bukan browser).
	//    CORS hanya relevan untuk akses dari web browser (halaman /docs).
	corsCfg := cors.Config{
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Content-Type", "Authorization"},
		AllowCredentials: true,
	}
	if config.Cfg.Env == "development" {
		corsCfg.AllowAllOrigins = true
	} else {
		// Origins dibaca dari CORS_ORIGIN di .env — tidak hardcoded lagi
		corsCfg.AllowOrigins = config.Cfg.CORSOrigins
	}
	r.Use(cors.New(corsCfg))

	// 7. Serve static files: uploads/previews dan uploads/originals
	//    URL penuh dibangun via utils.BuildPreviewURL(storedPath)
	//    Contoh: GET http://10.66.66.183:7000/uploads/surat_masuk/originals/xxx.jpg
	r.Static("/uploads", "./uploads")

	// 8. Register semua route API
	routes.SetupRoutes(r, svc)

	// 9. Start server
	log.Printf("Server berjalan di %s", config.Cfg.BaseURL)
	if err := r.Run(":" + config.Cfg.Port); err != nil {
		log.Fatal(err)
	}
}
