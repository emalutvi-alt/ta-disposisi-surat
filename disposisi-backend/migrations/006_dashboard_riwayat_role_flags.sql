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
