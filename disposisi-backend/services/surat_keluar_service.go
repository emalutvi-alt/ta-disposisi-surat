package services

import (
	"errors"
	"fmt"
	"log"
	"mime/multipart"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/helpers"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
	"gorm.io/gorm"
)

type SuratKeluarService struct {
	repo       *repositories.SuratKeluarRepository
	distri     *repositories.DistribusiSKRepository
	users      *repositories.UserRepository
	log        *LogService
	notif      *NotificationService
	pdfPreview *PDFPreviewService
}

func NewSuratKeluarService(
	repo *repositories.SuratKeluarRepository,
	distri *repositories.DistribusiSKRepository,
	users *repositories.UserRepository,
	log *LogService,
	notif *NotificationService,
	pdfPreview *PDFPreviewService,
) *SuratKeluarService {
	return &SuratKeluarService{
		repo:       repo,
		distri:     distri,
		users:      users,
		log:        log,
		notif:      notif,
		pdfPreview: pdfPreview,
	}
}

func (s *SuratKeluarService) Create(actorID uint, input dto.CreateSuratKeluarRequest, file *multipart.FileHeader) (*dto.SuratKeluarResponse, error) {
	tgl, err := time.Parse("2006-01-02", input.TanggalSurat)
	if err != nil {
		return nil, errors.New("format tanggal_surat harus YYYY-MM-DD")
	}

	saved, err := helpers.SaveUploadedFile(helpers.UploadSuratKeluar, file)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	var catatan, tujuan *string
	if input.Catatan != "" {
		catatan = &input.Catatan
	}
	if input.Tujuan != "" {
		tujuan = &input.Tujuan
	}

	sk := &models.SuratKeluar{
		KodeSurat:        input.KodeSurat,
		NoSurat:          input.NoSurat,
		Perihal:          input.Perihal,
		Catatan:          catatan,
		TanggalSurat:     tgl,
		Tujuan:           tujuan,
		FilePDF:          &saved.OriginalRel,
		FilePreview:      nil,
		StatusVerifikasi: "menunggu",
		StatusAlur:       "diterima_tu",
		CreatedAt:        now,
		UpdatedAt:        now,
		IsArsip:          false, // ← NEW
	}

	if err := s.repo.Create(sk); err != nil {
		return nil, err
	}

	// Generate preview
	if saved.IsPDF && s.pdfPreview != nil {
		pdfAbsPath, _ := helpers.AbsPath(saved.OriginalRel)
		genResult, genErr := s.pdfPreview.GeneratePreviews(GeneratePreviewsInput{
			PDFPath:   pdfAbsPath,
			SuratType: SuratKeluarType,
			SuratID:   sk.ID,
		})
		if genErr != nil {
			log.Printf("[SuratKeluar] Preview generation failed for ID=%d: %v", sk.ID, genErr)
		} else if genResult != nil {
			firstPage := genResult.FirstPagePath
			sk.FilePreview = &firstPage
			_ = s.repo.Update(sk)
		}
	} else if !saved.IsPDF && saved.PreviewRel != "" {
		sk.FilePreview = &saved.PreviewRel
		_ = s.repo.Update(sk)
	}

	s.log.WriteAuditLog(AuditLogInput{
		UserID:   &actorID,
		Action:   AuditCreateSuratKeluar,
		Table:    "surat_keluar",
		RecordID: &sk.ID,
		NewValue: sk.NoSurat,
	})
	s.notifyKepsekSuratKeluarBaru(actorID, sk)

	return s.buildResponseWithPages(sk)
}

func (s *SuratKeluarService) List(filter dto.SuratKeluarFilter) ([]dto.SuratKeluarResponse, error) {
	if filter.Status == "diproses" {
		filter.Status = "menunggu"
	}
	list, err := s.repo.List(filter)
	if err != nil {
		return nil, err
	}
	out := make([]dto.SuratKeluarResponse, 0, len(list))
	for i := range list {
		out = append(out, mapSuratKeluarResponse(&list[i]))
	}
	return out, nil
}

func (s *SuratKeluarService) GetByID(id uint) (*dto.SuratKeluarResponse, error) {
	sk, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}
	return s.buildResponseWithPages(sk)
}

func (s *SuratKeluarService) Update(actorID, id uint, input dto.UpdateSuratKeluarRequest, file *multipart.FileHeader) (*dto.SuratKeluarResponse, error) {
	sk, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}

	if input.KodeSurat > 0 {
		sk.KodeSurat = input.KodeSurat
	}
	if input.NoSurat != "" {
		sk.NoSurat = input.NoSurat
	}
	if input.Perihal != "" {
		sk.Perihal = input.Perihal
	}
	if input.Catatan != "" {
		sk.Catatan = &input.Catatan
	}
	if input.Tujuan != "" {
		sk.Tujuan = &input.Tujuan
	}
	if input.TanggalSurat != "" {
		tgl, err := time.Parse("2006-01-02", input.TanggalSurat)
		if err != nil {
			return nil, errors.New("format tanggal_surat harus YYYY-MM-DD")
		}
		sk.TanggalSurat = tgl
	}

	if file != nil {
		saved, err := helpers.SaveUploadedFile(helpers.UploadSuratKeluar, file)
		if err != nil {
			return nil, err
		}
		sk.FilePDF = &saved.OriginalRel
		sk.FilePreview = nil

		if saved.IsPDF && s.pdfPreview != nil {
			s.pdfPreview.CleanupPreviewFiles(SuratKeluarType, sk.ID)
			pdfAbsPath, _ := helpers.AbsPath(saved.OriginalRel)
			genResult, genErr := s.pdfPreview.GeneratePreviews(GeneratePreviewsInput{
				PDFPath:   pdfAbsPath,
				SuratType: SuratKeluarType,
				SuratID:   sk.ID,
			})
			if genErr != nil {
				log.Printf("[SuratKeluar] Preview re-generation failed for ID=%d: %v", sk.ID, genErr)
			} else if genResult != nil {
				firstPage := genResult.FirstPagePath
				sk.FilePreview = &firstPage
			}
		} else if !saved.IsPDF && saved.PreviewRel != "" {
			sk.FilePreview = &saved.PreviewRel
		}
	}

	sk.UpdatedAt = time.Now()
	if err := s.repo.Update(sk); err != nil {
		return nil, err
	}

	s.log.WriteAuditLog(AuditLogInput{
		UserID:   &actorID,
		Action:   AuditUpdateSuratKeluar,
		Table:    "surat_keluar",
		RecordID: &sk.ID,
		NewValue: sk.NoSurat,
	})

	return s.buildResponseWithPages(sk)
}

func (s *SuratKeluarService) Delete(actorID, id uint) error {
	_, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrSuratNotFound
		}
		return err
	}
	if err := s.repo.Delete(id); err != nil {
		return err
	}
	s.log.WriteAuditLog(AuditLogInput{
		UserID:   &actorID,
		Action:   AuditDeleteSuratKeluar,
		Table:    "surat_keluar",
		RecordID: &id,
	})
	return nil
}

func (s *SuratKeluarService) Verifikasi(id uint, verifierID uint, input dto.VerifikasiSuratKeluarRequest) (*dto.SuratKeluarResponse, error) {
	sk, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}

	now := time.Now()
	sk.UserVerifikasi = &verifierID
	sk.TanggalVerifikasi = &now
	if input.Catatan != "" {
		sk.CatatanVerifikasi = &input.Catatan
	}

	oldStatus := sk.StatusVerifikasi
	if input.IsApproved {
		sk.StatusVerifikasi = "disetujui"
		sk.StatusAlur = "diteruskan"
	} else {
		sk.StatusVerifikasi = "ditolak"
		sk.StatusAlur = "diterima_tu"
	}
	sk.UpdatedAt = now

	if err := s.repo.Update(sk); err != nil {
		return nil, err
	}

	s.log.WriteAuditLog(AuditLogInput{
		UserID:   &verifierID,
		Action:   AuditVerifySuratKeluar,
		Table:    "surat_keluar",
		RecordID: &sk.ID,
		OldValue: oldStatus,
		NewValue: sk.StatusVerifikasi,
	})
	s.notifyAdminsVerifikasiSK(verifierID, sk, input.IsApproved)

	resp := mapSuratKeluarResponse(sk)
	return &resp, nil
}

func (s *SuratKeluarService) Distribusi(actorID, id uint, input dto.DistribusiSuratKeluarRequest) error {
	sk, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrSuratNotFound
		}
		return err
	}

	if sk.StatusVerifikasi != "disetujui" {
		return errors.New("surat keluar harus disetujui sebelum distribusi")
	}

	now := time.Now()
	rows := make([]models.DistribusiSK, 0, len(input.UserIDs))
	for _, uid := range input.UserIDs {
		var cat *string
		if input.Catatan != "" {
			cat = &input.Catatan
		}
		rows = append(rows, models.DistribusiSK{
			SuratKeluarID: sk.ID,
			UserID:        uid,
			Status:        "belum_dibaca",
			DistributeAt:  now,
			Catatan:       cat,
		})
	}

	if err := s.distri.CreateBatch(rows); err != nil {
		return err
	}

	s.log.WriteAuditLog(AuditLogInput{
		UserID:   &actorID,
		Action:   AuditDistribusiSK,
		Table:    "surat_keluar",
		RecordID: &sk.ID,
		NewValue: sk.NoSurat,
	})
	skID := sk.ID
	_ = s.log.WriteDistribusiLog(DistribusiLogInput{
		SuratKeluarID: &skID,
		StatusTujuan:  "distribusi",
		UserID:        &actorID,
		Catatan:       "Distribusi ke " + fmt.Sprintf("%d", len(input.UserIDs)) + " penerima",
	})

	p := actorID
	for _, uid := range input.UserIDs {
		_ = s.notif.Create(CreateNotificationInput{
			PenerimaID:  uid,
			PengirimID:  &p,
			Type:        NotifTypeDistribusi,
			Title:       "Surat keluar baru",
			Message:     "Anda menerima surat keluar " + sk.NoSurat,
			ReferenceID: sk.ID,
		})
	}
	return nil
}

// ── ARSIP METHODS ────────────────────────────────────────────────────────

// Arsipkan memindahkan surat keluar ke arsip.
func (s *SuratKeluarService) Arsipkan(actorID, id uint) error {
	sk, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrSuratNotFound
		}
		return err
	}

	sk.IsArsip = true
	sk.StatusAlur = "diarsipkan"
	sk.UpdatedAt = time.Now()

	if err := s.repo.Update(sk); err != nil {
		return err
	}

	s.log.WriteAuditLog(AuditLogInput{
		UserID:   &actorID,
		Action:   "arsip_surat_keluar",
		Table:    "surat_keluar",
		RecordID: &sk.ID,
		NewValue: "diarsipkan",
	})
	return nil
}

// RestoreArsip mengembalikan surat keluar dari arsip.
func (s *SuratKeluarService) RestoreArsip(actorID, id uint) error {
	sk, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrSuratNotFound
		}
		return err
	}

	sk.IsArsip = false
	if sk.StatusVerifikasi == "disetujui" {
		sk.StatusAlur = "diteruskan"
	} else if sk.StatusVerifikasi == "ditolak" {
		sk.StatusAlur = "diterima_tu"
	} else {
		sk.StatusAlur = "diterima_tu"
	}
	sk.UpdatedAt = time.Now()

	if err := s.repo.Update(sk); err != nil {
		return err
	}

	s.log.WriteAuditLog(AuditLogInput{
		UserID:   &actorID,
		Action:   "restore_arsip_surat_keluar",
		Table:    "surat_keluar",
		RecordID: &sk.ID,
		NewValue: sk.StatusAlur,
	})
	return nil
}

// GetPages mengembalikan semua halaman preview untuk satu surat keluar.
func (s *SuratKeluarService) GetPages(suratID uint) ([]dto.PDFPageDTO, error) {
	if s.pdfPreview == nil {
		return []dto.PDFPageDTO{}, nil
	}
	pages, err := s.pdfPreview.GetPreviews(SuratKeluarType, suratID)
	if err != nil {
		return nil, err
	}
	result := make([]dto.PDFPageDTO, 0, len(pages))
	for _, p := range pages {
		result = append(result, dto.PDFPageDTO{
			PageNumber: p.PageNumber,
			ImageURL:   p.ImageURL,
		})
	}
	return result, nil
}

// buildResponseWithPages membangun SuratKeluarResponse lengkap termasuk semua halaman.
func (s *SuratKeluarService) buildResponseWithPages(sk *models.SuratKeluar) (*dto.SuratKeluarResponse, error) {
	resp := mapSuratKeluarResponse(sk)

	if s.pdfPreview != nil {
		pages, err := s.pdfPreview.GetPreviews(SuratKeluarType, sk.ID)
		if err == nil {
			resp.TotalPages = len(pages)
			for _, p := range pages {
				resp.Pages = append(resp.Pages, dto.PDFPageDTO{
					PageNumber: p.PageNumber,
					ImageURL:   p.ImageURL,
				})
			}
		}
	}

	return &resp, nil
}

func mapSuratKeluarResponse(sk *models.SuratKeluar) dto.SuratKeluarResponse {
	fileURL := ""
	previewURL := ""
	if sk.FilePDF != nil {
		fileURL = utils.BuildFileURL(*sk.FilePDF)
	}
	if sk.FilePreview != nil {
		previewURL = utils.BuildPreviewURL(*sk.FilePreview)
	}
	tujuan := ""
	if sk.Tujuan != nil {
		tujuan = *sk.Tujuan
	}
	return dto.SuratKeluarResponse{
		ID:               sk.ID,
		KodeSurat:        sk.KodeSurat,
		NoSurat:          sk.NoSurat,
		Perihal:          sk.Perihal,
		Tujuan:           tujuan,
		Status:           utils.MapStatusDisplay(sk.StatusVerifikasi),
		StatusVerifikasi: sk.StatusVerifikasi,
		StatusAlur:       sk.StatusAlur,
		FileURL:          fileURL,
		PreviewURL:       previewURL,
		TotalPages:       0,
		Pages:            nil,
		IsArsip:          sk.IsArsip, // ← NEW
		CreatedAt:        sk.CreatedAt,
	}
}

func (s *SuratKeluarService) notifyKepsekSuratKeluarBaru(pengirimID uint, sk *models.SuratKeluar) {
	ids, _ := s.users.FindIDsByLevelAkses(utils.LevelKepsek)
	p := pengirimID
	for _, uid := range ids {
		if uid == pengirimID {
			continue
		}
		_ = s.notif.Create(CreateNotificationInput{
			PenerimaID:  uid,
			PengirimID:  &p,
			Type:        NotifTypeSuratKeluar,
			Title:       "Surat keluar baru",
			Message:     "Surat " + sk.NoSurat + " menunggu verifikasi",
			ReferenceID: sk.ID,
		})
	}
}

func (s *SuratKeluarService) notifyAdminsVerifikasiSK(kepsekID uint, sk *models.SuratKeluar, approved bool) {
	ids, _ := s.users.FindIDsByLevelAkses(utils.LevelAdmin)
	p := kepsekID
	msg := "Surat keluar " + sk.NoSurat + " ditolak"
	if approved {
		msg = "Surat keluar " + sk.NoSurat + " disetujui"
	}
	for _, uid := range ids {
		_ = s.notif.Create(CreateNotificationInput{
			PenerimaID:  uid,
			PengirimID:  &p,
			Type:        NotifTypeApproval,
			Title:       "Verifikasi surat keluar",
			Message:     msg,
			ReferenceID: sk.ID,
			Rejected:    !approved,
		})
	}
}
