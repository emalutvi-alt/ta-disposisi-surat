package utils

// LevelAkses values from PostgreSQL jabatan.level_akses CHECK constraint.
const (
	LevelAdmin   = "admin"
	LevelKepsek  = "kepsek"
	LevelUser    = "user"
	LevelPegawai = "pegawai" // legacy DB value → treated as user for Flutter/RBAC
)

// FlutterRole values expected by mobile UI routing (Role enum).
const (
	FlutterTU     = "tu"
	FlutterKepsek = "kepsek"
	FlutterUsers  = "users"
)

// MapLevelToFlutter converts database level_akses to Flutter Role string.
func MapLevelToFlutter(level string) string {
	switch level {
	case LevelAdmin:
		return FlutterTU
	case LevelKepsek:
		return FlutterKepsek
	case LevelUser, LevelPegawai:
		return FlutterUsers
	default:
		return FlutterUsers
	}
}

// MapFlutterToLevel converts Flutter role back to database level_akses (for RBAC middleware).
func MapFlutterToLevel(flutterRole string) string {
	switch flutterRole {
	case FlutterTU:
		return LevelAdmin
	case FlutterKepsek:
		return LevelKepsek
	case FlutterUsers:
		return LevelUser
	default:
		return LevelUser
	}
}

// NormalizeLevelAkses maps legacy DB values to RBAC levels used in middleware.
func NormalizeLevelAkses(level string) string {
	switch level {
	case LevelAdmin:
		return LevelAdmin
	case LevelKepsek:
		return LevelKepsek
	case LevelUser, LevelPegawai, "":
		return LevelUser
	default:
		return LevelUser
	}
}
