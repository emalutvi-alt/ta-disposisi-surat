package utils

import (
	"errors"
	"strings"
)

var ErrInvalidNoSurat = errors.New("Nomor surat harus mengandung tanda '/' dan maksimal 50 karakter")

func ValidateNoSurat(noSurat string) error {
	noSurat = strings.TrimSpace(noSurat)
	if noSurat == "" || len(noSurat) > 50 || !strings.Contains(noSurat, "/") {
		return ErrInvalidNoSurat
	}
	return nil
}
