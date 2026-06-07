package utils

// MapStatusDisplay maps DB status_verifikasi to Flutter-friendly status.
func MapStatusDisplay(statusVerifikasi string) string {
	switch statusVerifikasi {
	case "menunggu":
		return "diproses"
	case "disetujui":
		return "disetujui"
	case "ditolak":
		return "ditolak"
	default:
		return statusVerifikasi
	}
}
