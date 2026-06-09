package repositories

import (
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/utils"
	"gorm.io/gorm"
)

type DashboardRepository struct {
	db *gorm.DB
}

func NewDashboardRepository(db *gorm.DB) *DashboardRepository {
	return &DashboardRepository{db: db}
}

func (r *DashboardRepository) CountSuratMasuk() (int64, error) {
	var n int64
	err := r.db.Table("surat_masuk").Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountSuratKeluar() (int64, error) {
	var n int64
	err := r.db.Table("surat_keluar").Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountDisposisi() (int64, error) {
	var n int64
	err := r.db.Table("disposisi").Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountSuratSelesai() (int64, error) {
	var sm, sk int64
	if err := r.db.Table("surat_masuk").Where("status_alur = ?", utils.StatusSelesai).Count(&sm).Error; err != nil {
		return 0, err
	}
	if err := r.db.Table("surat_keluar").Where("status_alur = ?", utils.StatusSelesai).Count(&sk).Error; err != nil {
		return 0, err
	}
	return sm + sk, nil
}

func (r *DashboardRepository) CountPendingDisposisiForUser(userID uint) (int64, error) {
	var n int64
	err := r.db.Table("distribusi_sm").
		Where("id_user = ? AND COALESCE(riwayat_user, false) = false", userID).
		Count(&n).Error
	return n, err
}

func (r *DashboardRepository) CountPendingSuratVerifikasi() (int64, error) {
	var sm, sk int64
	if err := r.db.Table("surat_masuk").Where("status_verifikasi = ?", utils.StatusMenungguPersetujuanKepsek).Count(&sm).Error; err != nil {
		return 0, err
	}
	if err := r.db.Table("surat_keluar").Where("status_verifikasi = ?", utils.StatusMenungguPersetujuanKepsek).Count(&sk).Error; err != nil {
		return 0, err
	}
	return sm + sk, nil
}

type RiwayatDateRange struct {
	Start *time.Time
	End   *time.Time
}

func (r *DashboardRepository) ListAktifTU() ([]dto.DashboardSuratItem, error) {
	var items []dto.DashboardSuratItem
	err := r.db.Raw(`
		SELECT id_surat_masuk AS id, 'surat_masuk' AS jenis_surat, no_surat,
		       perihal_surat AS perihal, asal_surat, '' AS tujuan,
		       status_alur AS status, status_verifikasi, status_alur,
		       tanggal_surat::text AS tanggal_surat, COALESCE(file_preview, '') AS preview_url,
		       created_at
		FROM surat_masuk
		WHERE COALESCE(riwayat_tu, false) = false
		  AND status_verifikasi IN (?, ?)
		UNION ALL
		SELECT id_surat_keluar AS id, 'surat_keluar' AS jenis_surat, no_surat,
		       perihal, '' AS asal_surat, COALESCE(tujuan, '') AS tujuan,
		       status_alur AS status, status_verifikasi, status_alur,
		       tanggal_surat::text AS tanggal_surat, COALESCE(file_preview, '') AS preview_url,
		       created_at
		FROM surat_keluar
		WHERE COALESCE(riwayat_tu, false) = false
		  AND status_verifikasi IN (?, ?)
		ORDER BY created_at DESC
	`, utils.StatusDitolakKepsek, utils.StatusDisetujuiKepsek, utils.StatusDitolakKepsek, utils.StatusDisetujuiKepsek).Scan(&items).Error
	return items, err
}

func (r *DashboardRepository) ListAktifKepsek() ([]dto.DashboardSuratItem, error) {
	var items []dto.DashboardSuratItem
	err := r.db.Raw(`
		SELECT id_surat_masuk AS id, 'surat_masuk' AS jenis_surat, no_surat,
		       perihal_surat AS perihal, asal_surat, '' AS tujuan,
		       status_alur AS status, status_verifikasi, status_alur,
		       tanggal_surat::text AS tanggal_surat, COALESCE(file_preview, '') AS preview_url,
		       created_at
		FROM surat_masuk
		WHERE status_verifikasi = ?
		UNION ALL
		SELECT id_surat_keluar AS id, 'surat_keluar' AS jenis_surat, no_surat,
		       perihal, '' AS asal_surat, COALESCE(tujuan, '') AS tujuan,
		       status_alur AS status, status_verifikasi, status_alur,
		       tanggal_surat::text AS tanggal_surat, COALESCE(file_preview, '') AS preview_url,
		       created_at
		FROM surat_keluar
		WHERE status_verifikasi = ?
		ORDER BY created_at DESC
	`, utils.StatusMenungguPersetujuanKepsek, utils.StatusMenungguPersetujuanKepsek).Scan(&items).Error
	return items, err
}

func (r *DashboardRepository) ListAktifWaka(userID uint) ([]dto.DashboardSuratItem, error) {
	var items []dto.DashboardSuratItem
	err := r.db.Raw(`
		SELECT sm.id_surat_masuk AS id, 'surat_masuk' AS jenis_surat, sm.no_surat,
		       sm.perihal_surat AS perihal, sm.asal_surat, '' AS tujuan,
		       sm.status_alur AS status, sm.status_verifikasi, sm.status_alur,
		       sm.tanggal_surat::text AS tanggal_surat, COALESCE(sm.file_preview, '') AS preview_url,
		       sm.created_at
		FROM disposisi d
		JOIN surat_masuk sm ON sm.id_surat_masuk = d.id_surat_masuk
		WHERE d.id_penerima = ?
		  AND COALESCE(d.riwayat_waka, false) = false
		  AND sm.status_alur = ?
		ORDER BY sm.created_at DESC
	`, userID, utils.StatusDikirimKeWaka).Scan(&items).Error
	return items, err
}

func (r *DashboardRepository) ListAktifUser(userID uint) ([]dto.DashboardSuratItem, error) {
	var items []dto.DashboardSuratItem
	err := r.db.Raw(`
		SELECT sm.id_surat_masuk AS id, 'surat_masuk' AS jenis_surat, sm.no_surat,
		       sm.perihal_surat AS perihal, sm.asal_surat, '' AS tujuan,
		       sm.status_alur AS status, sm.status_verifikasi, sm.status_alur,
		       sm.tanggal_surat::text AS tanggal_surat, COALESCE(sm.file_preview, '') AS preview_url,
		       sm.created_at
		FROM distribusi_sm ds
		JOIN disposisi d ON d.id_disposisi = ds.id_disposisi
		JOIN surat_masuk sm ON sm.id_surat_masuk = d.id_surat_masuk
		WHERE ds.id_user = ?
		  AND COALESCE(ds.riwayat_user, false) = false
		  AND sm.status_alur = ?
		ORDER BY sm.created_at DESC
	`, userID, utils.StatusDikirimKeUser).Scan(&items).Error
	return items, err
}

func (r *DashboardRepository) ListRiwayatTU(rangeFilter RiwayatDateRange) ([]dto.DashboardSuratItem, error) {
	var items []dto.DashboardSuratItem
	q := r.db.Raw(`
		SELECT * FROM (
			SELECT id_surat_masuk AS id, 'surat_masuk' AS jenis_surat, no_surat,
			       perihal_surat AS perihal, asal_surat, '' AS tujuan,
			       status_alur AS status, status_verifikasi, status_alur,
			       tanggal_surat::text AS tanggal_surat, COALESCE(file_preview, '') AS preview_url,
			       'tu' AS role_riwayat, created_at, tanggal_surat AS sort_tanggal
			FROM surat_masuk
			WHERE COALESCE(riwayat_tu, false) = true
			UNION ALL
			SELECT id_surat_keluar AS id, 'surat_keluar' AS jenis_surat, no_surat,
			       perihal, '' AS asal_surat, COALESCE(tujuan, '') AS tujuan,
			       status_alur AS status, status_verifikasi, status_alur,
			       tanggal_surat::text AS tanggal_surat, COALESCE(file_preview, '') AS preview_url,
			       'tu' AS role_riwayat, created_at, tanggal_surat AS sort_tanggal
			FROM surat_keluar
			WHERE COALESCE(riwayat_tu, false) = true
		) x
		WHERE (?::date IS NULL OR sort_tanggal >= ?::date)
		  AND (?::date IS NULL OR sort_tanggal <= ?::date)
		ORDER BY sort_tanggal DESC, created_at DESC
	`, rangeFilter.Start, rangeFilter.Start, rangeFilter.End, rangeFilter.End)
	err := q.Scan(&items).Error
	return items, err
}

func (r *DashboardRepository) ListRiwayatWaka(userID uint, rangeFilter RiwayatDateRange) ([]dto.DashboardSuratItem, error) {
	var items []dto.DashboardSuratItem
	err := r.db.Raw(`
		SELECT sm.id_surat_masuk AS id, 'surat_masuk' AS jenis_surat, sm.no_surat,
		       sm.perihal_surat AS perihal, sm.asal_surat, '' AS tujuan,
		       sm.status_alur AS status, sm.status_verifikasi, sm.status_alur,
		       sm.tanggal_surat::text AS tanggal_surat, COALESCE(sm.file_preview, '') AS preview_url,
		       'waka' AS role_riwayat, sm.created_at
		FROM disposisi d
		JOIN surat_masuk sm ON sm.id_surat_masuk = d.id_surat_masuk
		WHERE d.id_penerima = ?
		  AND COALESCE(d.riwayat_waka, false) = true
		  AND (?::date IS NULL OR sm.tanggal_surat >= ?::date)
		  AND (?::date IS NULL OR sm.tanggal_surat <= ?::date)
		ORDER BY sm.tanggal_surat DESC, sm.created_at DESC
	`, userID, rangeFilter.Start, rangeFilter.Start, rangeFilter.End, rangeFilter.End).Scan(&items).Error
	return items, err
}

func (r *DashboardRepository) ListRiwayatUser(userID uint, rangeFilter RiwayatDateRange) ([]dto.DashboardSuratItem, error) {
	var items []dto.DashboardSuratItem
	err := r.db.Raw(`
		SELECT sm.id_surat_masuk AS id, 'surat_masuk' AS jenis_surat, sm.no_surat,
		       sm.perihal_surat AS perihal, sm.asal_surat, '' AS tujuan,
		       sm.status_alur AS status, sm.status_verifikasi, sm.status_alur,
		       sm.tanggal_surat::text AS tanggal_surat, COALESCE(sm.file_preview, '') AS preview_url,
		       'user' AS role_riwayat, sm.created_at
		FROM distribusi_sm ds
		JOIN disposisi d ON d.id_disposisi = ds.id_disposisi
		JOIN surat_masuk sm ON sm.id_surat_masuk = d.id_surat_masuk
		WHERE ds.id_user = ?
		  AND COALESCE(ds.riwayat_user, false) = true
		  AND (?::date IS NULL OR sm.tanggal_surat >= ?::date)
		  AND (?::date IS NULL OR sm.tanggal_surat <= ?::date)
		ORDER BY sm.tanggal_surat DESC, sm.created_at DESC
	`, userID, rangeFilter.Start, rangeFilter.Start, rangeFilter.End, rangeFilter.End).Scan(&items).Error
	return items, err
}
