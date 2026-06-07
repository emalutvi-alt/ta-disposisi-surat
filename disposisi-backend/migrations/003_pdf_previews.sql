-- Migration: Tabel preview PDF multi-halaman
-- Aman dijalankan berkali-kali (IF NOT EXISTS)

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

-- Cleanup helper: hapus preview lama saat PDF di-replace
-- Dipanggil dari Go, bukan trigger, agar mudah ditest