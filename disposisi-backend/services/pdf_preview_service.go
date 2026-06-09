package services

import (
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/helpers"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
)

// PDFPreviewService mengelola konversi dan penyimpanan preview PDF multi-halaman.
type PDFPreviewService struct {
	repo *repositories.PDFPreviewRepository
}

func NewPDFPreviewService(repo *repositories.PDFPreviewRepository) *PDFPreviewService {
	return &PDFPreviewService{repo: repo}
}

// SuratType menandai jenis surat untuk path dan query.
type SuratType string

const (
	SuratMasukType  SuratType = "masuk"
	SuratKeluarType SuratType = "keluar"
)

// GeneratePreviewsInput data yang diperlukan untuk generate preview.
type GeneratePreviewsInput struct {
	PDFPath   string    // path absolut atau relatif ke file PDF asli
	SuratType SuratType // "masuk" | "keluar"
	SuratID   uint      // ID record surat
}

// GeneratePreviewsResult hasil generate preview.
type GeneratePreviewsResult struct {
	TotalPages    int
	Pages         []dto.PDFPageDTO
	FirstPagePath string // untuk kolom file_preview (backward compat)
}

// PagePreviewDTO adalah alias untuk backward compat internal — gunakan dto.PDFPageDTO di return publik.
type PagePreviewDTO = dto.PDFPageDTO

// GeneratePreviews adalah fungsi utama: konversi PDF → images → simpan DB.
//
// PENTING: Fungsi ini WAJIB memproses SEMUA halaman PDF.
// Tidak ada batasan pada halaman pertama saja.
func (s *PDFPreviewService) GeneratePreviews(input GeneratePreviewsInput) (*GeneratePreviewsResult, error) {
	if input.PDFPath == "" {
		return nil, fmt.Errorf("path PDF tidak boleh kosong")
	}
	if input.SuratID == 0 {
		return nil, fmt.Errorf("surat_id tidak boleh 0")
	}

	log.Printf("[PDFPreview] Mulai konversi %s_%d: %s",
		input.SuratType, input.SuratID, input.PDFPath)

	// 1. Hapus preview lama (untuk kasus re-upload PDF)
	if err := s.repo.DeleteBySurat(string(input.SuratType), input.SuratID); err != nil {
		log.Printf("[PDFPreview] Gagal hapus preview lama: %v", err)
		// Lanjutkan saja, bukan error fatal
	}

	// 2. Konversi SEMUA halaman PDF → PNG
	// ConvertPDFAllPages loop dari halaman 0 sampai totalPages-1
	convResult, err := helpers.ConvertPDFAllPages(
		input.PDFPath,
		string(input.SuratType),
		input.SuratID,
	)
	if err != nil {
		log.Printf("[PDFPreview] Konversi gagal untuk %s_%d: %v",
			input.SuratType, input.SuratID, err)

		// Fallback: simpan placeholder daripada error total
		return s.generateFallbackPreview(input)
	}

	// 3. Simpan metadata semua halaman ke database
	dbRows := make([]models.PDFPreview, 0, len(convResult.Pages))
	for _, page := range convResult.Pages {
		dbRows = append(dbRows, models.PDFPreview{
			SuratType:  string(input.SuratType),
			SuratID:    input.SuratID,
			PageNumber: page.PageNumber,
			ImagePath:  page.ImagePath,
		})
	}

	if err := s.repo.CreateBatch(dbRows); err != nil {
		log.Printf("[PDFPreview] Gagal simpan metadata ke DB: %v", err)
		// Tetap kembalikan hasil, file sudah ada di disk
	}

	// 4. Bangun response DTO
	result := &GeneratePreviewsResult{
		TotalPages:    convResult.TotalPages,
		FirstPagePath: convResult.FirstPagePath,
	}
	for _, page := range convResult.Pages {
		result.Pages = append(result.Pages, dto.PDFPageDTO{
			PageNumber: page.PageNumber,
			ImageURL:   buildPreviewImageURL(page.ImagePath),
		})
	}

	log.Printf("[PDFPreview] Selesai: %s_%d → %d halaman",
		input.SuratType, input.SuratID, convResult.TotalPages)

	return result, nil
}

// GetPreviews mengambil daftar halaman preview dari database.
// Dipakai oleh endpoint GET /surat-masuk/:id/pages dan GET /surat-keluar/:id/pages.
func (s *PDFPreviewService) GetPreviews(suratType SuratType, suratID uint) ([]dto.PDFPageDTO, error) {
	rows, err := s.repo.FindBySurat(string(suratType), suratID)
	if err != nil {
		return nil, fmt.Errorf("gagal ambil preview dari DB: %w", err)
	}

	result := make([]dto.PDFPageDTO, 0, len(rows))
	for _, row := range rows {
		result = append(result, dto.PDFPageDTO{
			PageNumber: row.PageNumber,
			ImageURL:   buildPreviewImageURL(row.ImagePath),
		})
	}

	return result, nil
}

// generateFallbackPreview dipakai saat konversi gagal total.
// Mengembalikan placeholder daripada error agar upload tetap berhasil.
func (s *PDFPreviewService) generateFallbackPreview(input GeneratePreviewsInput) (*GeneratePreviewsResult, error) {
	log.Printf("[PDFPreview] Menggunakan fallback placeholder untuk %s_%d",
		input.SuratType, input.SuratID)

	if err := helpers.EnsureDefaultPDFPlaceholder(); err != nil {
		return nil, fmt.Errorf("fallback placeholder gagal: %w", err)
	}

	// Simpan 1 baris fallback ke DB agar endpoint GET tidak kosong
	_ = s.repo.CreateBatch([]models.PDFPreview{{
		SuratType:  string(input.SuratType),
		SuratID:    input.SuratID,
		PageNumber: 1,
		ImagePath:  helpers.DefaultPDFPlaceholderRel,
	}})

	return &GeneratePreviewsResult{
		TotalPages:    1,
		FirstPagePath: helpers.DefaultPDFPlaceholderRel,
		Pages: []dto.PDFPageDTO{{
			PageNumber: 1,
			ImageURL:   buildPreviewImageURL(helpers.DefaultPDFPlaceholderRel),
		}},
	}, nil
}

// CleanupPreviewFiles menghapus file PNG dari disk (dipanggil saat surat dihapus).
func (s *PDFPreviewService) CleanupPreviewFiles(suratType SuratType, suratID uint) {
	previewDir := filepath.Join(helpers.PreviewBaseDir,
		fmt.Sprintf("%s_%d", suratType, suratID))

	if err := os.RemoveAll(previewDir); err != nil {
		log.Printf("[PDFPreview] Gagal hapus direktori preview %s: %v", previewDir, err)
	}

	if err := s.repo.DeleteBySurat(string(suratType), suratID); err != nil {
		log.Printf("[PDFPreview] Gagal hapus record preview di DB: %v", err)
	}
}

// buildPreviewImageURL mengonversi path relatif disk menjadi URL publik penuh.
// Contoh: "uploads/previews/masuk_1/page_1.png" → "http://192.168.x.x:7000/uploads/previews/masuk_1/page_1.png"
func buildPreviewImageURL(imagePath string) string {
	return utils.BuildPreviewURL(imagePath)
}

func (s *PDFPreviewService) SaveImagePreview(suratType SuratType, suratID uint, imagePath string) error {
	if imagePath == "" {
		return fmt.Errorf("path preview tidak boleh kosong")
	}
	if err := s.repo.DeleteBySurat(string(suratType), suratID); err != nil {
		return err
	}
	return s.repo.CreateBatch([]models.PDFPreview{{
		SuratType:  string(suratType),
		SuratID:    suratID,
		PageNumber: 1,
		ImagePath:  imagePath,
	}})
}
