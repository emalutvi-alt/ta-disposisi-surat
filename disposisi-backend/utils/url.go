package utils

import (
	"strings"

	"github.com/fiorelln/disposisi/config"
)

// BuildFileURL converts a stored relative path into a full public URL.
func BuildFileURL(storedPath string) string {
	return buildPublicURL(storedPath)
}

// BuildPreviewURL converts a stored file path into a full public URL for Flutter Image.network.
func BuildPreviewURL(storedPath string) string {
	return buildPublicURL(storedPath)
}

func buildPublicURL(storedPath string) string {
	if storedPath == "" {
		return ""
	}
	if strings.HasPrefix(storedPath, "http://") || strings.HasPrefix(storedPath, "https://") {
		return storedPath
	}
	path := strings.TrimPrefix(storedPath, "./")
	path = strings.TrimPrefix(path, "/")
	return strings.TrimRight(config.Cfg.BaseURL, "/") + "/" + path
}
