package utils

const (
	StatusMenungguPersetujuanKepsek = "MENUNGGU_PERSETUJUAN_KEPSEK"
	StatusDitolakKepsek             = "DITOLAK_KEPSEK"
	StatusDisetujuiKepsek           = "DISETUJUI_KEPSEK"
	StatusDikirimKeWaka             = "DIKIRIM_KE_WAKA"
	StatusDikirimKeUser             = "DIKIRIM_KE_USER"
	StatusDiterimaUser              = "DITERIMA_USER"
	StatusSelesai                   = "SELESAI"
)

// MapStatusDisplay maps DB status_verifikasi to Flutter-friendly status.
func MapStatusDisplay(statusVerifikasi string) string {
	switch statusVerifikasi {
	case "menunggu":
		return StatusMenungguPersetujuanKepsek
	case "disetujui":
		return StatusDisetujuiKepsek
	case "ditolak":
		return StatusDitolakKepsek
	default:
		return statusVerifikasi
	}
}
