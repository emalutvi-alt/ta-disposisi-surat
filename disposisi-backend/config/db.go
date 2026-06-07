package config

import (
	"fmt"
	"log"
	"os"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB
var JwtKey []byte

// ConnectDB opens PostgreSQL connection. Does NOT AutoMigrate existing tables.
func ConnectDB() {
	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")

	sslmode := os.Getenv("DB_SSLMODE")
	if sslmode == "" {
		sslmode = "disable"
	}

	dsn := fmt.Sprintf(
		"host=%s user=%s password=%s dbname=%s port=%s sslmode=%s",
		host, user, password, dbname, port, sslmode,
	)

	var err error
	DB, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("Gagal terhubung ke database:", err)
	}

	JwtKey = []byte(Cfg.JWTSecret)

	sqlDB, err := DB.DB()
	if err != nil {
		log.Fatal("Gagal ambil sql.DB:", err)
	}

	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	if err := runSafeMigrations(DB); err != nil {
		log.Fatal("Migration gagal:", err)
	}

	log.Println("Database berhasil terhubung (schema PostgreSQL existing, no AutoMigrate)")
}

// runSafeMigrations applies only backward-compatible DDL changes.
func runSafeMigrations(db *gorm.DB) error {
    // Migration lama (file_preview column)
    err := db.Exec(`
        ALTER TABLE surat_masuk ADD COLUMN IF NOT EXISTS file_preview VARCHAR(500);
        ALTER TABLE surat_keluar ADD COLUMN IF NOT EXISTS file_preview VARCHAR(500);
    `).Error
    if err != nil {
        return err
    }

    // Migration baru (tabel pdf_previews)
    err = db.Exec(`
        CREATE TABLE IF NOT EXISTS pdf_previews (
            id          BIGSERIAL    PRIMARY KEY,
            surat_type  VARCHAR(20)  NOT NULL CHECK (surat_type IN ('masuk', 'keluar')),
            surat_id    BIGINT       NOT NULL,
            page_number INT          NOT NULL CHECK (page_number >= 1),
            image_path  VARCHAR(500) NOT NULL,
            created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
            UNIQUE (surat_type, surat_id, page_number)
        );
        CREATE INDEX IF NOT EXISTS idx_pdf_previews_lookup
            ON pdf_previews (surat_type, surat_id, page_number);
    `).Error
    if err != nil {
        return err
    }

    // ← NEW: Migration arsip columns
    err = db.Exec(`
        ALTER TABLE surat_masuk ADD COLUMN IF NOT EXISTS is_arsip BOOLEAN DEFAULT FALSE;
        ALTER TABLE surat_keluar ADD COLUMN IF NOT EXISTS is_arsip BOOLEAN DEFAULT FALSE;
        UPDATE surat_masuk SET is_arsip = FALSE WHERE is_arsip IS NULL;
        UPDATE surat_keluar SET is_arsip = FALSE WHERE is_arsip IS NULL;
        CREATE INDEX IF NOT EXISTS idx_surat_masuk_arsip ON surat_masuk(is_arsip);
        CREATE INDEX IF NOT EXISTS idx_surat_keluar_arsip ON surat_keluar(is_arsip);
    `).Error
    if err != nil {
        return err
    }

    return nil
}
