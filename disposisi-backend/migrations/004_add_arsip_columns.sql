
# File Fix 17: Migration SQL untuk kolom is_arsip
migration_arsip_sql = '''-- Migration 004: Add arsip columns to surat_masuk and surat_keluar
-- Aman dijalankan berkali-kali (IF NOT EXISTS)

-- Add is_arsip to surat_masuk
ALTER TABLE surat_masuk
    ADD COLUMN IF NOT EXISTS is_arsip BOOLEAN DEFAULT FALSE;

-- Add is_arsip to surat_keluar
ALTER TABLE surat_keluar
    ADD COLUMN IF NOT EXISTS is_arsip BOOLEAN DEFAULT FALSE;

-- Update existing data (set all to false if null)
UPDATE surat_masuk SET is_arsip = FALSE WHERE is_arsip IS NULL;
UPDATE surat_keluar SET is_arsip = FALSE WHERE is_arsip IS NULL;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_surat_masuk_arsip ON surat_masuk(is_arsip);
CREATE INDEX IF NOT EXISTS idx_surat_keluar_arsip ON surat_keluar(is_arsip);
'''

with open('/mnt/agents/output/004_add_arsip_columns.sql', 'w') as f:
    f.write(migration_arsip_sql)
print("✅ 004_add_arsip_columns.sql created")
