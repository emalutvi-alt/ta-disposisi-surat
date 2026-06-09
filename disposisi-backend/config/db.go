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

	return db.Exec(`
        ALTER TABLE log
            ADD COLUMN IF NOT EXISTS role VARCHAR(50),
            ADD COLUMN IF NOT EXISTS entity VARCHAR(100),
            ADD COLUMN IF NOT EXISTS entity_id BIGINT,
            ADD COLUMN IF NOT EXISTS old_status VARCHAR(50),
            ADD COLUMN IF NOT EXISTS new_status VARCHAR(50),
            ADD COLUMN IF NOT EXISTS ip_address VARCHAR(100),
            ADD COLUMN IF NOT EXISTS user_agent TEXT;

        ALTER TABLE surat_masuk
            ADD COLUMN IF NOT EXISTS riwayat_tu BOOLEAN NOT NULL DEFAULT FALSE;
        ALTER TABLE surat_keluar
            ADD COLUMN IF NOT EXISTS riwayat_tu BOOLEAN NOT NULL DEFAULT FALSE;
        ALTER TABLE disposisi
            ADD COLUMN IF NOT EXISTS riwayat_waka BOOLEAN NOT NULL DEFAULT FALSE;
        ALTER TABLE distribusi_sm
            ADD COLUMN IF NOT EXISTS riwayat_user BOOLEAN NOT NULL DEFAULT FALSE;

        CREATE INDEX IF NOT EXISTS idx_surat_masuk_riwayat_tu
            ON surat_masuk (riwayat_tu, tanggal_surat);
        CREATE INDEX IF NOT EXISTS idx_surat_keluar_riwayat_tu
            ON surat_keluar (riwayat_tu, tanggal_surat);
        CREATE INDEX IF NOT EXISTS idx_disposisi_riwayat_waka
            ON disposisi (id_penerima, riwayat_waka);
        CREATE INDEX IF NOT EXISTS idx_distribusi_sm_riwayat_user
            ON distribusi_sm (id_user, riwayat_user);

        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_surat_masuk_no_surat_final') THEN
                ALTER TABLE surat_masuk ADD CONSTRAINT chk_surat_masuk_no_surat_final
                CHECK (position('/' in no_surat) > 0 AND char_length(no_surat) <= 50) NOT VALID;
            END IF;
            IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'chk_surat_keluar_no_surat_final') THEN
                ALTER TABLE surat_keluar ADD CONSTRAINT chk_surat_keluar_no_surat_final
                CHECK (position('/' in no_surat) > 0 AND char_length(no_surat) <= 50) NOT VALID;
            END IF;
        END $$;

        CREATE OR REPLACE FUNCTION prevent_delete_surat()
        RETURNS trigger AS $$
        BEGIN
            RAISE EXCEPTION 'Surat tidak boleh dihapus';
        END;
        $$ LANGUAGE plpgsql;

        DROP TRIGGER IF EXISTS trg_prevent_delete_surat_masuk ON surat_masuk;
        CREATE TRIGGER trg_prevent_delete_surat_masuk
        BEFORE DELETE ON surat_masuk
        FOR EACH ROW EXECUTE FUNCTION prevent_delete_surat();

        DROP TRIGGER IF EXISTS trg_prevent_delete_surat_keluar ON surat_keluar;
        CREATE TRIGGER trg_prevent_delete_surat_keluar
        BEFORE DELETE ON surat_keluar
        FOR EACH ROW EXECUTE FUNCTION prevent_delete_surat();
    `).Error
}
