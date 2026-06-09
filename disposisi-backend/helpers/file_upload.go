package helpers

import (
	"errors"
	"fmt"
	"io"
	"mime/multipart"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
)

const MaxUploadSize = 10 << 20 // 10MB

var allowedExtensions = map[string]bool{
	".pdf":  true,
	".jpg":  true,
	".jpeg": true,
	".png":  true,
}

var allowedMimes = map[string]bool{
	"application/pdf": true,
	"image/jpeg":      true,
	"image/png":       true,
}

// UploadCategory identifies surat storage root (surat_masuk | surat_keluar).
type UploadCategory string

const (
	UploadSuratMasuk  UploadCategory = "surat_masuk"
	UploadSuratKeluar UploadCategory = "surat_keluar"
)

// SavedUpload holds relative paths stored in DB (forward slashes).
type SavedUpload struct {
	OriginalRel string
	PreviewRel  string
	IsPDF       bool
}

// ValidateUploadFile checks size, extension, and MIME type.
func ValidateUploadFile(file *multipart.FileHeader) error {
	if file == nil {
		return fmt.Errorf("File wajib diupload")
	}
	if file.Size == 0 {
		return fmt.Errorf("File wajib diupload")
	}
	if file.Size > MaxUploadSize {
		return fmt.Errorf("ukuran file maksimal 10MB")
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	if !allowedExtensions[ext] {
		return fmt.Errorf("Format file tidak didukung. Gunakan PDF, JPG, JPEG, atau PNG")
	}

	mime := file.Header.Get("Content-Type")
	if mime != "" && !allowedMimes[mime] {
		return fmt.Errorf("Format file tidak didukung. Gunakan PDF, JPG, JPEG, atau PNG")
	}
	if ext == ".pdf" {
		if err := validateMultipartPDF(file); err != nil {
			return fmt.Errorf("File PDF tidak valid")
		}
	}

	return nil
}

func validateMultipartPDF(file *multipart.FileHeader) error {
	src, err := file.Open()
	if err != nil {
		return err
	}
	defer src.Close()

	header := make([]byte, 5)
	if _, err := io.ReadFull(src, header); err != nil {
		return err
	}
	if string(header) != "%PDF-" {
		return fmt.Errorf("invalid pdf header")
	}
	return nil
}

// SaveUploadedFile menyimpan file upload dan mengembalikan path.
// Untuk PDF: path asli dikembalikan; konversi preview dilakukan
// oleh PDFPreviewService setelah surat_id tersedia.
func SaveUploadedFile(category UploadCategory, file *multipart.FileHeader) (*SavedUpload, error) {
	if err := ValidateUploadFile(file); err != nil {
		return nil, err
	}

	ext := strings.ToLower(filepath.Ext(file.Filename))
	isPDF := ext == ".pdf"

	uid := uuid.New().String()
	ts := time.Now().Unix()
	base := fmt.Sprintf("%s_%d_%s", category, ts, uid[:8])

	origDir := filepath.Join("uploads", string(category), "originals")
	if err := os.MkdirAll(origDir, 0o755); err != nil {
		return nil, err
	}

	origName := base + ext
	origPath := filepath.Join(origDir, origName)

	src, err := file.Open()
	if err != nil {
		return nil, err
	}
	defer src.Close()

	dst, err := os.Create(origPath)
	if err != nil {
		return nil, err
	}
	if _, err := io.Copy(dst, src); err != nil {
		dst.Close()
		return nil, err
	}
	dst.Close()

	origRel := filepath.ToSlash(origPath)
	result := &SavedUpload{
		OriginalRel: origRel,
		IsPDF:       isPDF,
		// PreviewRel akan diisi setelah ConvertPDFAllPages dipanggil
		// dengan surat_id yang tersedia.
	}

	if !isPDF {
		// Untuk image (jpg/png): langsung copy ke previews
		prevDir := filepath.Join("uploads", string(category), "previews")
		if err := os.MkdirAll(prevDir, 0o755); err != nil {
			return nil, err
		}
		prevPath := filepath.Join(prevDir, base+ext)
		if err := copyFile(origPath, prevPath); err != nil {
			return nil, err
		}
		result.PreviewRel = filepath.ToSlash(prevPath)
	}

	return result, nil
}

func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	return err
}

// ResolveUploadByBasename finds a file under uploads/ by base filename (no path traversal).
func ResolveUploadByBasename(filename string) (string, error) {
	clean := filepath.Base(strings.TrimSpace(filename))
	if clean == "" || clean == "." || clean == ".." {
		return "", fmt.Errorf("nama file tidak valid")
	}
	if strings.ContainsAny(clean, `/\`) {
		return "", fmt.Errorf("nama file tidak valid")
	}

	absUploads, err := filepath.Abs("uploads")
	if err != nil {
		return "", err
	}

	var found string
	stopWalk := errors.New("stop walk")
	err = filepath.WalkDir(absUploads, func(path string, d os.DirEntry, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		if d.IsDir() {
			return nil
		}
		if filepath.Base(path) == clean {
			found = path
			return stopWalk
		}
		return nil
	})
	if err != nil && !errors.Is(err, stopWalk) {
		return "", err
	}
	if found == "" {
		return "", fmt.Errorf("file tidak ditemukan")
	}

	absFound, err := filepath.Abs(found)
	if err != nil {
		return "", err
	}
	if !strings.HasPrefix(absFound, absUploads+string(os.PathSeparator)) {
		return "", fmt.Errorf("akses file ditolak")
	}
	return absFound, nil
}

func ResolvePreviewPath(relPath string) (string, error) {
	clean := filepath.Clean(strings.TrimSpace(relPath))
	if clean == "" || filepath.IsAbs(clean) || strings.Contains(clean, "..") {
		return "", fmt.Errorf("path preview tidak valid")
	}
	if strings.Contains(filepath.ToSlash(clean), "/originals/") {
		return "", fmt.Errorf("akses file ditolak")
	}
	if !strings.Contains(filepath.ToSlash(clean), "previews/") && !strings.Contains(filepath.ToSlash(clean), "default/") {
		return "", fmt.Errorf("akses file ditolak")
	}

	absUploads, err := filepath.Abs("uploads")
	if err != nil {
		return "", err
	}
	absPath, err := filepath.Abs(clean)
	if err != nil {
		return "", err
	}
	if absPath != absUploads && !strings.HasPrefix(absPath, absUploads+string(os.PathSeparator)) {
		return "", fmt.Errorf("akses file ditolak")
	}
	if _, err := os.Stat(absPath); err != nil {
		return "", fmt.Errorf("file tidak ditemukan")
	}
	return absPath, nil
}

// AbsPath mengonversi path relatif ke path absolut berdasarkan working directory saat runtime.
// Dipakai sebelum memanggil pdftoppm/ImageMagick agar path valid di semua OS.
// Jika path sudah absolut, dikembalikan apa adanya.
func AbsPath(relPath string) (string, error) {
	if filepath.IsAbs(relPath) {
		return relPath, nil
	}
	abs, err := filepath.Abs(relPath)
	if err != nil {
		return relPath, err // fallback ke path asli jika gagal
	}
	return abs, nil
}
