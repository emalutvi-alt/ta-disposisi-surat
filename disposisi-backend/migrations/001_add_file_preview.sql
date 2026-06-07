-- Backward-compatible migration: add preview path columns for mobile image viewer.
-- Safe to run multiple times (IF NOT EXISTS).

ALTER TABLE surat_masuk
    ADD COLUMN IF NOT EXISTS file_preview VARCHAR(500);

ALTER TABLE surat_keluar
    ADD COLUMN IF NOT EXISTS file_preview VARCHAR(500);
