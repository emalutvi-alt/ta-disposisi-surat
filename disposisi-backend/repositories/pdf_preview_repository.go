package repositories

import (
    "github.com/fiorelln/disposisi/models"
    "gorm.io/gorm"
)

type PDFPreviewRepository struct {
    db *gorm.DB
}

func NewPDFPreviewRepository(db *gorm.DB) *PDFPreviewRepository {
    return &PDFPreviewRepository{db: db}
}

// CreateBatch menyimpan semua halaman preview sekaligus dalam satu transaksi.
func (r *PDFPreviewRepository) CreateBatch(previews []models.PDFPreview) error {
    if len(previews) == 0 {
        return nil
    }
    return r.db.CreateInBatches(previews, 50).Error
}

// FindBySurat mengambil semua halaman preview untuk surat tertentu, urut page_number ASC.
func (r *PDFPreviewRepository) FindBySurat(suratType string, suratID uint) ([]models.PDFPreview, error) {
    var rows []models.PDFPreview
    err := r.db.
        Where("surat_type = ? AND surat_id = ?", suratType, suratID).
        Order("page_number ASC").
        Find(&rows).Error
    return rows, err
}

// DeleteBySurat menghapus semua preview lama sebelum re-upload PDF.
func (r *PDFPreviewRepository) DeleteBySurat(suratType string, suratID uint) error {
    return r.db.
        Where("surat_type = ? AND surat_id = ?", suratType, suratID).
        Delete(&models.PDFPreview{}).Error
}

// CountBySurat mengembalikan jumlah halaman yang sudah tergenerate.
func (r *PDFPreviewRepository) CountBySurat(suratType string, suratID uint) (int64, error) {
    var count int64
    err := r.db.Model(&models.PDFPreview{}).
        Where("surat_type = ? AND surat_id = ?", suratType, suratID).
        Count(&count).Error
    return count, err
}