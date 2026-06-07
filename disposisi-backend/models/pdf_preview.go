package models

import "time"

// PDFPreview mewakili satu halaman hasil render dari sebuah PDF surat.
// Satu surat bisa memiliki banyak baris — satu per halaman.
type PDFPreview struct {
    ID         uint      `gorm:"primaryKey;column:id"           json:"id"`
    SuratType  string    `gorm:"column:surat_type;not null"     json:"surat_type"` // "masuk" | "keluar"
    SuratID    uint      `gorm:"column:surat_id;not null"       json:"surat_id"`
    PageNumber int       `gorm:"column:page_number;not null"    json:"page_number"` // 1-based
    ImagePath  string    `gorm:"column:image_path;not null"     json:"image_path"`  // path relatif
    CreatedAt  time.Time `gorm:"column:created_at;autoCreateTime" json:"created_at"`
}

func (PDFPreview) TableName() string {
    return "pdf_previews"
}