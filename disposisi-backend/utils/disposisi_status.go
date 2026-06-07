package utils

// MapDisposisiStatusToAPI maps DB status_disposisi + approval to Flutter-friendly status.
func MapDisposisiStatusToAPI(statusDisposisi, statusApproval string) string {
	if statusApproval == "ditolak" {
		return "ditolak"
	}
	switch statusDisposisi {
	case "belum_dibaca":
		return "pending"
	case "dibaca", "sedang_dikerjakan":
		return "diterima"
	case "selesai":
		return "selesai"
	default:
		return statusDisposisi
	}
}

// MapAPIStatusToDB maps API ?status= filter to DB status_disposisi values.
func MapAPIStatusToDB(apiStatus string) string {
	switch apiStatus {
	case "pending":
		return "belum_dibaca"
	case "diterima":
		return "dibaca" // repository also matches sedang_dikerjakan
	case "selesai":
		return "selesai"
	case "ditolak":
		return "" // filtered via status_approval in repository
	default:
		return apiStatus
	}
}
