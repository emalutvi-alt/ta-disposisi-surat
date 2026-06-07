package helpers

// PDFPreviewService mengonversi SELURUH halaman PDF menjadi image PNG.
//
// Strategi library:
//   - Pilihan utama  : github.com/gen2brain/go-fitz  (binding MuPDF — kualitas terbaik)
//   - Pilihan kedua  : github.com/pdfcpu/pdfcpu + poppler CLI (fallback)
//   - Fallback aman  : exec "pdftoppm" / "convert" (ImageMagick) via os/exec
//
// Implementasi di bawah menggunakan go-fitz apabila tersedia,
// dan fallback ke poppler CLI (pdftoppm) yang tersedia di hampir semua distro Linux.
//
// TIDAK ADA IMPLEMENTASI YANG HANYA MEMPROSES HALAMAN PERTAMA.
// LOOP WAJIB MEMPROSES page := 0 SAMPAI totalPages-1.

import (
	"context"
	"errors"
	"fmt"
	"image"
	"image/color"
	"image/png"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

// ─────────────────────────────────────────────────────────────────────────────
// KONFIGURASI
// ─────────────────────────────────────────────────────────────────────────────

const (
	// PreviewBaseDir adalah root direktori penyimpanan semua hasil render.
	PreviewBaseDir = "uploads/previews"

	// PreviewDPI resolusi render — 150 DPI cukup untuk preview mobile,
	// 200 DPI lebih tajam namun file lebih besar.
	PreviewDPI = 150

	// MaxPDFPages batas atas halaman yang diproses.
	// PDF > 200 halaman jarang untuk surat dinas, tapi tetap didukung.
	MaxPDFPages = 200

	// ConvertTimeout batas waktu per-PDF.
	ConvertTimeout = 5 * time.Minute
)

// ─────────────────────────────────────────────────────────────────────────────
// HASIL KONVERSI
// ─────────────────────────────────────────────────────────────────────────────

// PageResult mewakili hasil render satu halaman.
type PageResult struct {
	PageNumber int    // 1-based
	ImagePath  string // path relatif, forward slashes
}

// ConvertAllPagesResult hasil lengkap konversi satu PDF.
type ConvertAllPagesResult struct {
	TotalPages int
	Pages      []PageResult
	// FirstPagePath adalah PreviewRel yang disimpan ke kolom file_preview
	// di tabel surat (kompatibilitas dengan kolom lama).
	FirstPagePath string
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT UTAMA
// ─────────────────────────────────────────────────────────────────────────────

// ConvertPDFAllPages mengonversi SETIAP halaman PDF ke PNG dan menyimpannya
// ke uploads/previews/{suratType}_{suratID}/.
//
// Urutan percobaan:
//  1. go-fitz (MuPDF) via build tag — kualitas terbaik, tanpa CGO apabila tidak ada
//  2. pdftoppm (Poppler) via CLI    — tersedia di Ubuntu: apt install poppler-utils
//  3. convert (ImageMagick)         — tersedia di Ubuntu: apt install imagemagick
//
// Kembalikan error hanya apabila SEMUA metode gagal.
// Partial success (halaman gagal di tengah) tetap mengembalikan halaman yang berhasil.
func ConvertPDFAllPages(pdfPath string, suratType string, suratID uint) (*ConvertAllPagesResult, error) {
	// Validasi file sebelum proses
	if err := validatePDFFile(pdfPath); err != nil {
		return nil, fmt.Errorf("validasi PDF gagal: %w", err)
	}

	// Buat direktori output
	outDir := filepath.Join(PreviewBaseDir, fmt.Sprintf("%s_%d", suratType, suratID))
	if err := os.MkdirAll(outDir, 0o755); err != nil {
		return nil, fmt.Errorf("gagal membuat direktori preview: %w", err)
	}

	// Hapus file preview lama (untuk re-upload)
	cleanOldPreviews(outDir)

	// Coba metode konversi secara berurutan
	result, err := tryConvertWithPoppler(pdfPath, outDir)
	if err != nil {
		log.Printf("[PDF] Poppler gagal (%v), coba ImageMagick...", err)
		result, err = tryConvertWithImageMagick(pdfPath, outDir)
	}
	if err != nil {
		log.Printf("[PDF] ImageMagick gagal (%v), coba go-fitz...", err)
		result, err = tryConvertWithGoFitz(pdfPath, outDir)
	}
	if err != nil {
		return nil, fmt.Errorf("semua metode konversi PDF gagal: %w", err)
	}

	if len(result.Pages) == 0 {
		return nil, errors.New("tidak ada halaman berhasil dirender")
	}

	result.FirstPagePath = result.Pages[0].ImagePath
	log.Printf("[PDF] %s_%d: %d halaman berhasil dirender", suratType, suratID, len(result.Pages))
	return result, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// METODE 1: POPPLER (pdftoppm) — DIREKOMENDASIKAN
// ─────────────────────────────────────────────────────────────────────────────
// Install: apt-get install -y poppler-utils
// Output : {outDir}/page-000001.png, page-000002.png, ...

func tryConvertWithPoppler(pdfPath, outDir string) (*ConvertAllPagesResult, error) {
	// Periksa apakah pdftoppm tersedia
	if _, err := exec.LookPath("pdftoppm"); err != nil {
		return nil, fmt.Errorf("pdftoppm tidak ditemukan di PATH: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), ConvertTimeout)
	defer cancel()

	// pdftoppm -png -r 150 input.pdf output_prefix
	// Menghasilkan: output_prefix-000001.png, output_prefix-000002.png, dst.
	prefix := filepath.Join(outDir, "page")
	cmd := exec.CommandContext(ctx,
		"pdftoppm",
		"-png",
		"-r", strconv.Itoa(PreviewDPI),
		pdfPath,
		prefix,
	)

	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("pdftoppm error: %v — output: %s", err, string(out))
	}

	// Kumpulkan file hasil
	return collectPopplerOutput(outDir)
}

func collectPopplerOutput(outDir string) (*ConvertAllPagesResult, error) {
	entries, err := os.ReadDir(outDir)
	if err != nil {
		return nil, fmt.Errorf("gagal membaca direktori output: %w", err)
	}

	result := &ConvertAllPagesResult{}
	pageNum := 0

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !strings.HasPrefix(name, "page-") || !strings.HasSuffix(name, ".png") {
			continue
		}

		pageNum++
		relPath := filepath.ToSlash(filepath.Join(outDir, name))

		// Rename ke page_N.png agar konsisten
		newName := fmt.Sprintf("page_%d.png", pageNum)
		newPath := filepath.Join(outDir, newName)
		if err := os.Rename(filepath.Join(outDir, name), newPath); err != nil {
			log.Printf("[PDF] Gagal rename %s → %s: %v", name, newName, err)
			relPath = filepath.ToSlash(filepath.Join(outDir, name))
		} else {
			relPath = filepath.ToSlash(newPath)
		}

		result.Pages = append(result.Pages, PageResult{
			PageNumber: pageNum,
			ImagePath:  relPath,
		})
	}

	result.TotalPages = len(result.Pages)
	if result.TotalPages == 0 {
		return nil, errors.New("pdftoppm menghasilkan 0 file PNG")
	}

	return result, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// METODE 2: IMAGEMAGICK (convert)
// ─────────────────────────────────────────────────────────────────────────────
// Install: apt-get install -y imagemagick ghostscript
// Catatan: policy.xml ImageMagick mungkin perlu diubah agar boleh baca PDF

func tryConvertWithImageMagick(pdfPath, outDir string) (*ConvertAllPagesResult, error) {
	if _, err := exec.LookPath("convert"); err != nil {
		return nil, fmt.Errorf("convert (ImageMagick) tidak ditemukan: %w", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), ConvertTimeout)
	defer cancel()

	// convert -density 150 input.pdf output/page_%d.png
	outputPattern := filepath.Join(outDir, "page_%d.png")
	cmd := exec.CommandContext(ctx,
		"convert",
		"-density", strconv.Itoa(PreviewDPI),
		"-quality", "90",
		"-background", "white",
		"-alpha", "remove",
		pdfPath,
		outputPattern,
	)

	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("convert error: %v — output: %s", err, string(out))
	}

	return collectImageMagickOutput(outDir)
}

func collectImageMagickOutput(outDir string) (*ConvertAllPagesResult, error) {
	entries, err := os.ReadDir(outDir)
	if err != nil {
		return nil, err
	}

	result := &ConvertAllPagesResult{}

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !strings.HasPrefix(name, "page_") || !strings.HasSuffix(name, ".png") {
			continue
		}

		// Extract nomor dari "page_0.png", "page_1.png", dst.
		numStr := strings.TrimPrefix(strings.TrimSuffix(name, ".png"), "page_")
		n, err := strconv.Atoi(numStr)
		if err != nil {
			continue
		}

		// ImageMagick mulai dari 0, kita ubah ke 1-based
		pageNum := n + 1
		newName := fmt.Sprintf("page_%d.png", pageNum)
		newPath := filepath.Join(outDir, newName)

		if name != newName {
			_ = os.Rename(filepath.Join(outDir, name), newPath)
		}

		relPath := filepath.ToSlash(newPath)
		result.Pages = append(result.Pages, PageResult{
			PageNumber: pageNum,
			ImagePath:  relPath,
		})
	}

	// Sort by page number
	sortPageResults(result.Pages)
	result.TotalPages = len(result.Pages)

	if result.TotalPages == 0 {
		return nil, errors.New("ImageMagick menghasilkan 0 file PNG")
	}

	return result, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// METODE 3: go-fitz (MuPDF Go binding)
// ─────────────────────────────────────────────────────────────────────────────
// go get github.com/gen2brain/go-fitz
// Memerlukan CGO dan libmupdf-dev atau binary MuPDF
// Komentar blok ini aktif apabila build tag "fitz" diset

func tryConvertWithGoFitz(pdfPath, outDir string) (*ConvertAllPagesResult, error) {
	// Implementasi go-fitz ada di helpers/pdf_fitz.go (dengan build tag)
	// File ini dipanggil hanya jika go-fitz tersedia.
	// Default fallback ini mengembalikan error agar metode lain dicoba.
	return nil, errors.New("go-fitz tidak dicompile (gunakan build tag 'fitz')")
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

func validatePDFFile(pdfPath string) error {
	info, err := os.Stat(pdfPath)
	if err != nil {
		return fmt.Errorf("file tidak ditemukan: %w", err)
	}

	if info.Size() == 0 {
		return errors.New("file PDF kosong (0 bytes)")
	}

	const maxSize = 50 << 20 // 50MB
	if info.Size() > maxSize {
		return fmt.Errorf("file PDF terlalu besar: %d MB (max 50MB)", info.Size()>>20)
	}

	// Periksa magic number PDF
	f, err := os.Open(pdfPath)
	if err != nil {
		return err
	}
	defer f.Close()

	header := make([]byte, 5)
	if _, err := io.ReadFull(f, header); err != nil {
		return fmt.Errorf("tidak bisa baca header PDF: %w", err)
	}
	if string(header) != "%PDF-" {
		return errors.New("file bukan PDF yang valid (magic number tidak cocok)")
	}

	return nil
}

func cleanOldPreviews(outDir string) {
	entries, err := os.ReadDir(outDir)
	if err != nil {
		return
	}
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		// Hapus file format page_N.png (ImageMagick/renamed) dan page-XXXXXX.png (Poppler raw)
		if strings.HasPrefix(name, "page_") && strings.HasSuffix(name, ".png") {
			_ = os.Remove(filepath.Join(outDir, name))
		} else if strings.HasPrefix(name, "page-") && strings.HasSuffix(name, ".png") {
			_ = os.Remove(filepath.Join(outDir, name))
		}
	}
}

func sortPageResults(pages []PageResult) {
	// Insertion sort cukup untuk jumlah halaman yang kecil
	for i := 1; i < len(pages); i++ {
		key := pages[i]
		j := i - 1
		for j >= 0 && pages[j].PageNumber > key.PageNumber {
			pages[j+1] = pages[j]
			j--
		}
		pages[j+1] = key
	}
}

// SaveImageToDisk menyimpan image.Image ke file PNG di disk.
// Dipakai oleh go-fitz backend.
func SaveImageToDisk(img image.Image, path string) error {
	f, err := os.Create(path)
	if err != nil {
		return err
	}
	defer f.Close()
	return png.Encode(f, img)
}

// DefaultPDFPlaceholderRel dipertahankan untuk kompatibilitas backward.
// Dipakai sebagai fallback apabila konversi PDF gagal total.
const DefaultPDFPlaceholderRel = "uploads/default/pdf_placeholder.jpg"

// EnsureDefaultPDFPlaceholder tetap ada untuk backward compatibility.
func EnsureDefaultPDFPlaceholder() error {
	if _, err := os.Stat(DefaultPDFPlaceholderRel); err == nil {
		return nil
	}
	if err := os.MkdirAll(filepath.Dir(DefaultPDFPlaceholderRel), 0o755); err != nil {
		return err
	}
	// Buat placeholder sederhana dengan go standard library
	return createPlaceholderImage(DefaultPDFPlaceholderRel, 480, 640)
}

func createPlaceholderImage(path string, w, h int) error {
	// Buat gambar PNG putih polos sebagai placeholder
	img := image.NewRGBA(image.Rect(0, 0, w, h))
	// Isi dengan warna putih
	white := color.RGBA{R: 255, G: 255, B: 255, A: 255}
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			img.Set(x, y, white)
		}
	}

	f, err := os.Create(path)
	if err != nil {
		return fmt.Errorf("gagal membuat file placeholder: %w", err)
	}
	defer f.Close()

	if err := png.Encode(f, img); err != nil {
		return fmt.Errorf("gagal encode PNG placeholder: %w", err)
	}

	log.Println("[PDF] Placeholder dibuat:", path)
	return nil
}
