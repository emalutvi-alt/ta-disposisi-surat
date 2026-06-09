ALTER TABLE log
    ADD COLUMN IF NOT EXISTS role VARCHAR(50),
    ADD COLUMN IF NOT EXISTS entity VARCHAR(100),
    ADD COLUMN IF NOT EXISTS entity_id BIGINT,
    ADD COLUMN IF NOT EXISTS old_status VARCHAR(50),
    ADD COLUMN IF NOT EXISTS new_status VARCHAR(50),
    ADD COLUMN IF NOT EXISTS ip_address VARCHAR(100),
    ADD COLUMN IF NOT EXISTS user_agent TEXT;

ALTER TABLE surat_masuk
    ADD CONSTRAINT chk_surat_masuk_no_surat_final
    CHECK (position('/' in no_surat) > 0 AND char_length(no_surat) <= 50) NOT VALID;

ALTER TABLE surat_keluar
    ADD CONSTRAINT chk_surat_keluar_no_surat_final
    CHECK (position('/' in no_surat) > 0 AND char_length(no_surat) <= 50) NOT VALID;

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
