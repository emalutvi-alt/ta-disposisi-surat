package config

import (
	"log"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

// App holds runtime configuration loaded from environment variables.
type App struct {
	Port            string
	BaseURL         string
	Env             string
	JWTSecret       string
	JWTExpiration   string
	ResendAPIKey    string
	ResendFromEmail string
	CORSOrigins     []string

	// SMTP (tambah ini)
	SMTPHost     string
	SMTPPort     string
	SMTPEmail    string
	SMTPPassword string
	SMTPFromName string
}

var Cfg App

// LoadEnv membaca .env dan menginisialisasi Cfg.
// FATAL jika JWT_SECRET tidak diset.
// WARNING jika BASE_URL tidak diset (preview URL akan mengarah ke localhost).
func LoadEnv() {
	if err := godotenv.Load(); err != nil {
		log.Println("warning: .env not loaded:", err)
	}

	port := os.Getenv("SERVER_PORT")
	if port == "" {
		port = "7000"
	}

	// ── BASE_URL ─────────────────────────────────────────────────────────────
	// BASE_URL WAJIB diset di .env agar Flutter Image.network() bisa load
	// preview surat di HP fisik.
	//
	// Contoh .env:
	//   BASE_URL=http://192.168.1.100:7000
	//
	// Cara cek IP server:
	//   Windows : ipconfig     → IPv4 Address
	//   Linux   : hostname -I  → baris pertama
	baseURL := os.Getenv("BASE_URL")
	if baseURL == "" {
		baseURL = "http://localhost:" + port
		log.Println("┌─────────────────────────────────────────────────────────┐")
		log.Println("│  WARNING: BASE_URL tidak diset di .env                  │")
		log.Printf("│  Fallback: %-43s │", baseURL)
		log.Println("│  Flutter Image.network() AKAN GAGAL di HP fisik!        │")
		log.Println("│  Solusi: tambahkan di .env →                            │")
		log.Printf("│    BASE_URL=http://[IP_SERVER]:%s                       │", port)
		log.Println("└─────────────────────────────────────────────────────────┘")
	}

	// ── JWT ──────────────────────────────────────────────────────────────────
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		log.Fatal("FATAL: JWT_SECRET tidak diset di .env — server tidak dapat dijalankan")
	}

	jwtExp := os.Getenv("JWT_EXPIRATION")
	if jwtExp == "" {
		jwtExp = "168h"
	}

	// ── SERVER ENV ───────────────────────────────────────────────────────────
	env := os.Getenv("SERVER_ENV")
	if env == "" {
		env = "development"
	}

	// ── CORS ORIGINS ─────────────────────────────────────────────────────────
	// CORS_ORIGIN: origins yang boleh akses API dari browser (bukan mobile Flutter).
	// Flutter Dio tidak terpengaruh CORS, ini hanya untuk web browser / docs.
	// Format: http://IP:PORT (pisah koma jika lebih dari satu)
	corsOrigins := parseCORSOrigins(os.Getenv("CORS_ORIGIN"), baseURL)

	// ── SMTP ─────────────────────────────────────────────────────────────────
	Cfg = App{
		Port:            port,
		BaseURL:         baseURL,
		Env:             env,
		JWTSecret:       secret,
		JWTExpiration:   jwtExp,
		ResendAPIKey:    os.Getenv("RESEND_API_KEY"),
		ResendFromEmail: os.Getenv("EMAIL_FROM"),
		CORSOrigins:     corsOrigins,

		// SMTP (tambah ini)
		SMTPHost:     os.Getenv("SMTP_HOST"),
		SMTPPort:     os.Getenv("SMTP_PORT"),
		SMTPEmail:    os.Getenv("SMTP_EMAIL"),
		SMTPPassword: os.Getenv("SMTP_PASSWORD"),
		SMTPFromName: os.Getenv("SMTP_FROM_NAME"),
	}
}

// parseCORSOrigins mengurai CORS_ORIGIN dari env.
// Fallback ke slice berisi baseURL jika env kosong.
func parseCORSOrigins(raw, fallback string) []string {
	if raw == "" {
		return []string{fallback}
	}
	var result []string
	for _, o := range strings.Split(raw, ",") {
		o = strings.TrimSpace(o)
		if o != "" {
			result = append(result, o)
		}
	}
	if len(result) == 0 {
		return []string{fallback}
	}
	return result
}
