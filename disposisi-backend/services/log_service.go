package services

import (
	"log"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/repositories"
	"gorm.io/gorm"
)

// Audit action constants (used across services — do not hardcode strings elsewhere).
const (
	AuditLogin            = "login"
	AuditLogout           = "logout"
	AuditCreateSuratMasuk = "create_surat_masuk"
	AuditUpdateSuratMasuk = "update_surat_masuk"
	AuditDeleteSuratMasuk = "delete_surat_masuk"
	AuditVerifySuratMasuk = "verify_surat_masuk"
	AuditCreateSuratKeluar = "create_surat_keluar"
	AuditUpdateSuratKeluar = "update_surat_keluar"
	AuditDeleteSuratKeluar = "delete_surat_keluar"
	AuditVerifySuratKeluar = "verify_surat_keluar"
	AuditDistribusiSK     = "distribusi_surat_keluar"
	AuditCreateDisposisi  = "create_disposisi"
	AuditApproveDisposisi = "approve_disposisi"
	AuditDownloadFile     = "download_file"
)

type LogService struct {
	audit *repositories.LogRepository
	dist  *repositories.LogDistribusiRepository
}

func NewLogService(
	audit *repositories.LogRepository,
	dist *repositories.LogDistribusiRepository,
) *LogService {
	return &LogService{audit: audit, dist: dist}
}

type AuditLogInput struct {
	UserID     *uint
	Action     string
	Table      string
	RecordID   *uint
	OldValue   string
	NewValue   string
}

type DistribusiLogInput struct {
	SuratMasukID  *uint
	SuratKeluarID *uint
	StatusAsal    string
	StatusTujuan  string
	UserID        *uint
	Catatan       string
}

func (s *LogService) WriteAuditLog(input AuditLogInput) {
	entry := &models.Log{
		UserID:       input.UserID,
		Aksi:         strPtr(input.Action),
		TabelTerkait: strPtrEmpty(input.Table),
		UpdatedAt:    time.Now(),
	}
	if input.RecordID != nil {
		id := int(*input.RecordID)
		entry.IDData = &id
	}
	if input.OldValue != "" {
		entry.ValuesOld = &input.OldValue
	}
	if input.NewValue != "" {
		entry.ValuesNew = &input.NewValue
	}
	if err := s.audit.Create(entry); err != nil {
		log.Printf("[audit] write failed action=%s: %v", input.Action, err)
	}
}

func (s *LogService) WriteDistribusiLog(input DistribusiLogInput) error {
	var cat *string
	if input.Catatan != "" {
		cat = &input.Catatan
	}
	var asal, tujuan *string
	if input.StatusAsal != "" {
		asal = &input.StatusAsal
	}
	if input.StatusTujuan != "" {
		tujuan = &input.StatusTujuan
	}
	return s.dist.Create(&models.LogDistribusi{
		SuratMasukID:  input.SuratMasukID,
		SuratKeluarID: input.SuratKeluarID,
		StatusAsal:    asal,
		StatusTujuan:  tujuan,
		UserID:        input.UserID,
		Catatan:       cat,
		CreatedAt:     time.Now(),
	})
}

func (s *LogService) WriteDistribusiLogTx(tx *gorm.DB, input DistribusiLogInput) error {
	var cat *string
	if input.Catatan != "" {
		cat = &input.Catatan
	}
	var asal, tujuan *string
	if input.StatusAsal != "" {
		asal = &input.StatusAsal
	}
	if input.StatusTujuan != "" {
		tujuan = &input.StatusTujuan
	}
	return s.dist.CreateWithTx(tx, &models.LogDistribusi{
		SuratMasukID:  input.SuratMasukID,
		SuratKeluarID: input.SuratKeluarID,
		StatusAsal:    asal,
		StatusTujuan:  tujuan,
		UserID:        input.UserID,
		Catatan:       cat,
		CreatedAt:     time.Now(),
	})
}

func (s *LogService) ListAuditLogs(q dto.AuditLogListQuery) (*dto.AuditLogListData, error) {
	page, limit := normalizePageLimit(q.Page, q.Limit)
	list, total, err := s.audit.List(repositories.AuditLogListParams{
		Page:   page,
		Limit:  limit,
		Search: q.Search,
	})
	if err != nil {
		return nil, err
	}

	items := make([]dto.AuditLogResponse, 0, len(list))
	for i := range list {
		items = append(items, mapAuditLogResponse(&list[i]))
	}
	return &dto.AuditLogListData{
		Items: items,
		Page:  page,
		Limit: limit,
		Total: total,
	}, nil
}

func mapAuditLogResponse(l *models.Log) dto.AuditLogResponse {
	action := ""
	if l.Aksi != nil {
		action = *l.Aksi
	}
	table := ""
	if l.TabelTerkait != nil {
		table = *l.TabelTerkait
	}
	oldV, newV := "", ""
	if l.ValuesOld != nil {
		oldV = *l.ValuesOld
	}
	if l.ValuesNew != nil {
		newV = *l.ValuesNew
	}
	return dto.AuditLogResponse{
		ID:        l.ID,
		UserID:    l.UserID,
		Action:    action,
		Table:     table,
		RecordID:  l.IDData,
		OldValue:  oldV,
		NewValue:  newV,
		CreatedAt: l.UpdatedAt,
	}
}

func strPtrEmpty(s string) *string {
	if s == "" {
		return nil
	}
	return &s
}

func strPtr(s string) *string {
	return &s
}

