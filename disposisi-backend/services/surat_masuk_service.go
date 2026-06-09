package services

import (
	"errors"
	"log"
	"mime/multipart"
	"strings"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/helpers"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
	"gorm.io/gorm"
)

var ErrSuratNotFound = errors.New("surat tidak ditemukan")

// SuratMasukService mengelola bisnis logic surat masuk.
type SuratMasukService struct {
	repo         *repositories.SuratMasukRepository
	users        *repositories.UserRepository
	logSvc       *LogService
	notif        *NotificationService
	disposisiSvc *DisposisiService
	pdfPreview   *PDFPreviewService // ← multi-page preview
}

// NewSuratMasukService membangun SuratMasukService dengan semua dependency-nya.
func NewSuratMasukService(
	repo *repositories.SuratMasukRepository,
	users *repositories.UserRepository,
	logSvc *LogService,
	notif *NotificationService,
	disposisiSvc *DisposisiService,
	pdfPreview *PDFPreviewService,
) *SuratMasukService {
	return &SuratMasukService{
		repo:         repo,
		users:        users,
		logSvc:       logSvc,
		notif:        notif,
		disposisiSvc: disposisiSvc,
		pdfPreview:   pdfPreview,
	}
}

// Create menyimpan surat masuk baru dan men-generate preview PDF multi-halaman.
func (s *SuratMasukService) Create(actorID uint, input dto.CreateSuratMasukRequest, file *multipart.FileHeader) (*dto.SuratMasukResponse, error) {
	if err := utils.ValidateNoSurat(input.NoSurat); err != nil {
		return nil, err
	}
	tgl, err := time.Parse("2006-01-02", input.TanggalSurat)
	if err != nil {
		return nil, errors.New("format tanggal_surat harus YYYY-MM-DD")
	}

	// Simpan file PDF/image ke disk
	saved, err := helpers.SaveUploadedFile(helpers.UploadSuratMasuk, file)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	sm := &models.SuratMasuk{
		NoSurat:          input.NoSurat,
		PerihalSurat:     input.PerihalSurat,
		AsalSurat:        input.AsalSurat,
		TanggalSurat:     tgl,
		FilePDF:          &saved.OriginalRel,
		FilePreview:      nil, // akan diisi setelah generate preview
		StatusVerifikasi: utils.StatusMenungguPersetujuanKepsek,
		StatusAlur:       utils.StatusMenungguPersetujuanKepsek,
		TanggalDiterima:  &now,
		CreatedAt:        now,
		UpdatedAt:        now,
	}

	if err := s.repo.Create(sm); err != nil {
		return nil, err
	}

	// Generate preview SETELAH surat_id tersedia (ID dari DB)
	if saved.IsPDF && s.pdfPreview != nil {
		pdfAbsPath, _ := helpers.AbsPath(saved.OriginalRel)
		genResult, genErr := s.pdfPreview.GeneratePreviews(GeneratePreviewsInput{
			PDFPath:   pdfAbsPath,
			SuratType: SuratMasukType,
			SuratID:   sm.ID,
		})
		if genErr != nil {
			log.Printf("[SuratMasuk] Preview generation failed for ID=%d: %v", sm.ID, genErr)
			// Upload tetap sukses walau preview gagal
		} else if genResult != nil {
			// Update kolom file_preview ke halaman pertama (backward compat)
			firstPage := genResult.FirstPagePath
			sm.FilePreview = &firstPage
			_ = s.repo.Update(sm)
		}
	} else if !saved.IsPDF && saved.PreviewRel != "" {
		// Untuk image biasa (jpg/png): simpan path preview langsung
		sm.FilePreview = &saved.PreviewRel
		if s.pdfPreview != nil {
			_ = s.pdfPreview.SaveImagePreview(SuratMasukType, sm.ID, saved.PreviewRel)
		}
		_ = s.repo.Update(sm)
	}

	// Audit log
	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID:    &actorID,
		Action:    AuditCreateSuratMasuk,
		Table:     "surat_masuk",
		RecordID:  &sm.ID,
		NewValue:  sm.NoSurat,
		NewStatus: sm.StatusAlur,
	})

	// Notifikasi ke kepsek
	s.notifyKepsekSuratBaru(actorID, sm)

	return s.buildResponseWithPages(sm)
}

// List mengembalikan daftar surat masuk sesuai filter.
func (s *SuratMasukService) List(filter dto.SuratMasukFilter) ([]dto.SuratMasukResponse, error) {
	list, err := s.repo.List(filter)
	if err != nil {
		return nil, err
	}
	out := make([]dto.SuratMasukResponse, 0, len(list))
	for i := range list {
		resp := mapSuratMasukResponse(&list[i])
		out = append(out, resp)
	}
	return out, nil
}

// GetByID mengambil satu surat masuk beserta daftar semua halaman preview.
func (s *SuratMasukService) GetByID(id uint) (*dto.SuratMasukResponse, error) {
	sm, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}
	return s.buildResponseWithPages(sm)
}

// Update mengubah data surat masuk; jika file baru dikirim, preview di-regenerate.
func (s *SuratMasukService) Update(actorID, id uint, input dto.UpdateSuratMasukRequest, file *multipart.FileHeader) (*dto.SuratMasukResponse, error) {
	sm, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}

	if input.NoSurat != "" {
		if err := utils.ValidateNoSurat(input.NoSurat); err != nil {
			return nil, err
		}
		sm.NoSurat = input.NoSurat
	}
	if input.PerihalSurat != "" {
		sm.PerihalSurat = input.PerihalSurat
	}
	if input.AsalSurat != "" {
		sm.AsalSurat = input.AsalSurat
	}
	if input.TanggalSurat != "" {
		tgl, err := time.Parse("2006-01-02", input.TanggalSurat)
		if err != nil {
			return nil, errors.New("format tanggal_surat harus YYYY-MM-DD")
		}
		sm.TanggalSurat = tgl
	}

	if file != nil {
		saved, err := helpers.SaveUploadedFile(helpers.UploadSuratMasuk, file)
		if err != nil {
			return nil, err
		}
		sm.FilePDF = &saved.OriginalRel
		sm.FilePreview = nil

		if saved.IsPDF && s.pdfPreview != nil {
			// Hapus preview lama dari disk
			s.pdfPreview.CleanupPreviewFiles(SuratMasukType, sm.ID)

			pdfAbsPath, _ := helpers.AbsPath(saved.OriginalRel)
			genResult, genErr := s.pdfPreview.GeneratePreviews(GeneratePreviewsInput{
				PDFPath:   pdfAbsPath,
				SuratType: SuratMasukType,
				SuratID:   sm.ID,
			})
			if genErr != nil {
				log.Printf("[SuratMasuk] Preview re-generation failed for ID=%d: %v", sm.ID, genErr)
			} else if genResult != nil {
				firstPage := genResult.FirstPagePath
				sm.FilePreview = &firstPage
			}
		} else if !saved.IsPDF && saved.PreviewRel != "" {
			sm.FilePreview = &saved.PreviewRel
			if s.pdfPreview != nil {
				_ = s.pdfPreview.SaveImagePreview(SuratMasukType, sm.ID, saved.PreviewRel)
			}
		}
	}

	sm.UpdatedAt = time.Now()
	if err := s.repo.Update(sm); err != nil {
		return nil, err
	}

	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID:   &actorID,
		Action:   AuditUpdateSuratMasuk,
		Table:    "surat_masuk",
		RecordID: &sm.ID,
		NewValue: sm.NoSurat,
	})

	return s.buildResponseWithPages(sm)
}

// Delete menghapus surat masuk beserta file preview-nya.
func (s *SuratMasukService) Delete(actorID, id uint) error {
	_, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrSuratNotFound
		}
		return err
	}

	// Hapus file preview dari disk + DB
	if s.pdfPreview != nil {
		s.pdfPreview.CleanupPreviewFiles(SuratMasukType, id)
	}

	if err := s.repo.Delete(id); err != nil {
		return err
	}

	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID:   &actorID,
		Action:   AuditDeleteSuratMasuk,
		Table:    "surat_masuk",
		RecordID: &id,
	})
	return nil
}

// Verifikasi memproses keputusan kepsek (approve/tolak) dan membuat disposisi jika disetujui.
func (s *SuratMasukService) Verifikasi(id, userID uint, input dto.VerifikasiSuratMasukRequest) (*dto.SuratMasukResponse, error) {
	sm, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}

	now := time.Now()
	sm.UserVerifikasi = &userID
	sm.TanggalVerifikasi = &now
	if input.Catatan != "" {
		sm.CatatanVerifikasi = &input.Catatan
	}

	oldStatus := sm.StatusVerifikasi
	if input.IsApproved {
		sm.StatusVerifikasi = utils.StatusDisetujuiKepsek
		sm.StatusAlur = utils.StatusDisetujuiKepsek
	} else {
		if input.Catatan == "" {
			return nil, errors.New("Catatan Kepala Sekolah wajib diisi")
		}
		sm.StatusVerifikasi = utils.StatusDitolakKepsek
		sm.StatusAlur = utils.StatusDitolakKepsek
	}
	sm.UpdatedAt = now

	if err := s.repo.Update(sm); err != nil {
		return nil, err
	}

	// Buat disposisi jika ada tujuan yang ditentukan
	if input.IsApproved && len(input.TujuanIDs) > 0 {
		_, err := s.disposisiSvc.Create(userID, dto.CreateDisposisiRequest{
			SuratMasukID:         id,
			TujuanIDs:            input.TujuanIDs,
			TanggapanSaran:       input.TanggapanSaran,
			ProsesLanjut:         input.ProsesLanjut,
			KoordinasiKonfirmasi: input.KoordinasiKonfirmasi,
		})
		if err != nil {
			log.Printf("[SuratMasuk] gagal buat disposisi setelah verifikasi id=%d: %v", id, err)
		}
	}

	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID:    &userID,
		Action:    AuditVerifySuratMasuk,
		Table:     "surat_masuk",
		RecordID:  &sm.ID,
		OldValue:  oldStatus,
		NewValue:  sm.StatusVerifikasi,
		OldStatus: oldStatus,
		NewStatus: sm.StatusAlur,
	})

	s.notifyAdminsVerifikasi(userID, sm, input.IsApproved)

	return s.buildResponseWithPages(sm)
}

func (s *SuratMasukService) KonfirmasiTU(actorID, id uint, input dto.KonfirmasiTUSuratMasukRequest) (*dto.SuratMasukResponse, error) {
	sm, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}

	oldStatus := sm.StatusAlur
	if sm.StatusVerifikasi == utils.StatusDitolakKepsek {
		sm.StatusAlur = utils.StatusSelesai
		sm.RiwayatTU = true
	} else if sm.StatusVerifikasi == utils.StatusDisetujuiKepsek {
		if len(input.WakaIDs) == 0 {
			return nil, errors.New("Wakil Kepala Sekolah wajib dipilih")
		}
		for _, wakaID := range input.WakaIDs {
			catatan := ""
			if sm.CatatanVerifikasi != nil {
				catatan = *sm.CatatanVerifikasi
			}
			if _, err := s.disposisiSvc.Create(actorID, dto.CreateDisposisiRequest{
				SuratMasukID: sm.ID,
				TujuanIDs:    []uint{wakaID},
				Catatan:      catatan,
			}); err != nil && !errors.Is(err, ErrDuplicatePenerima) {
				return nil, err
			}
			p := actorID
			_ = s.notif.Create(CreateNotificationInput{
				PenerimaID:  wakaID,
				PengirimID:  &p,
				Type:        NotifTypeDisposisi,
				Title:       "Surat masuk untuk Waka",
				Message:     "Surat " + sm.NoSurat + " dikirim ke Wakil Kepala Sekolah",
				ReferenceID: sm.ID,
			})
		}
		sm.StatusAlur = utils.StatusDikirimKeWaka
		sm.RiwayatTU = true
	} else {
		return nil, errors.New("surat belum dapat dikonfirmasi TU")
	}

	sm.UpdatedAt = time.Now()
	if err := s.repo.Update(sm); err != nil {
		return nil, err
	}
	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID: &actorID, Action: "konfirmasi_tu_surat_masuk", Table: "surat_masuk",
		RecordID: &sm.ID, OldStatus: oldStatus, NewStatus: sm.StatusAlur,
	})
	return s.buildResponseWithPages(sm)
}

func (s *SuratMasukService) KirimKeUser(wakaID, id uint, input dto.KirimSuratMasukKeUserRequest) (*dto.SuratMasukResponse, error) {
	if strings.TrimSpace(input.Catatan) == "" {
		return nil, errors.New("Catatan Wakil Kepala Sekolah wajib diisi")
	}
	sm, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}
	if sm.StatusAlur != utils.StatusDikirimKeWaka {
		return nil, errors.New("surat belum dikirim ke Waka")
	}
	wakaDisposisis, err := s.disposisiSvc.disposisi.FindBySuratMasukID(id)
	if err != nil {
		return nil, err
	}
	var disposisiID uint
	for _, d := range wakaDisposisis {
		if d.PenerimaID == wakaID {
			disposisiID = d.ID
			break
		}
	}
	if disposisiID == 0 {
		return nil, errors.New("akses surat ditolak")
	}
	now := time.Now()
	for _, uid := range input.UserIDs {
		if _, err := s.users.FindByID(uid); err != nil {
			return nil, ErrInvalidTujuan
		}
		if err := s.disposisiSvc.distribusi.CreateBatch([]models.DistribusiSM{{
			DisposisiID: disposisiID,
			UserID:      &uid,
			CreatedAt:   now,
			Status:      utils.StatusDikirimKeUser,
		}}); err != nil {
			return nil, err
		}
		p := wakaID
		_ = s.notif.Create(CreateNotificationInput{
			PenerimaID:  uid,
			PengirimID:  &p,
			Type:        NotifTypeDisposisi,
			Title:       "Surat masuk baru",
			Message:     "Anda menerima surat " + sm.NoSurat,
			ReferenceID: sm.ID,
		})
	}
	oldStatus := sm.StatusAlur
	sm.StatusAlur = utils.StatusDikirimKeUser
	sm.UpdatedAt = now
	if err := s.repo.Update(sm); err != nil {
		return nil, err
	}
	if err := s.disposisiSvc.disposisi.MarkRiwayatWaka(id, wakaID); err != nil {
		return nil, err
	}
	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID: &wakaID, Action: "waka_mengirim_surat_ke_penerima", Table: "surat_masuk",
		RecordID: &sm.ID, OldStatus: oldStatus, NewStatus: sm.StatusAlur,
	})
	return s.buildResponseWithPages(sm)
}

func (s *SuratMasukService) KonfirmasiPenerimaan(userID, id uint) (*dto.SuratMasukResponse, error) {
	sm, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}
	now := time.Now()
	authorized, err := s.disposisiSvc.distribusi.MarkRiwayatUserBySurat(id, userID, now)
	if err != nil {
		return nil, err
	}
	if !authorized {
		return nil, errors.New("akses surat ditolak")
	}
	oldStatus := sm.StatusAlur
	sm.StatusAlur = utils.StatusSelesai
	sm.StatusVerifikasi = utils.StatusDiterimaUser
	sm.UpdatedAt = now
	if err := s.repo.Update(sm); err != nil {
		return nil, err
	}
	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID: &userID, Action: "user_konfirmasi_penerimaan", Table: "surat_masuk",
		RecordID: &sm.ID, OldStatus: oldStatus, NewStatus: sm.StatusAlur,
	})
	return s.buildResponseWithPages(sm)
}

// GetPages mengembalikan semua halaman preview untuk satu surat masuk.
// Dipakai oleh endpoint GET /surat-masuk/:id/pages.
func (s *SuratMasukService) GetPages(suratID uint) ([]dto.PDFPageDTO, error) {
	if s.pdfPreview == nil {
		return []dto.PDFPageDTO{}, nil
	}
	pages, err := s.pdfPreview.GetPreviews(SuratMasukType, suratID)
	if err != nil {
		return nil, err
	}
	// Konversi dari PagePreviewDTO (service internal) ke PDFPageDTO (dto package)
	result := make([]dto.PDFPageDTO, 0, len(pages))
	for _, p := range pages {
		result = append(result, dto.PDFPageDTO{
			PageNumber: p.PageNumber,
			ImageURL:   p.ImageURL,
		})
	}
	return result, nil
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS INTERNAL
// ─────────────────────────────────────────────────────────────────────────────

// buildResponseWithPages membangun SuratMasukResponse lengkap termasuk semua halaman.
func (s *SuratMasukService) buildResponseWithPages(sm *models.SuratMasuk) (*dto.SuratMasukResponse, error) {
	resp := mapSuratMasukResponse(sm)

	// Ambil daftar semua halaman dari DB
	if s.pdfPreview != nil {
		pages, err := s.pdfPreview.GetPreviews(SuratMasukType, sm.ID)
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

// mapSuratMasukResponse memetakan model ke DTO response.
func mapSuratMasukResponse(sm *models.SuratMasuk) dto.SuratMasukResponse {
	fileURL := ""
	previewURL := ""
	_ = fileURL
	if sm.FilePreview != nil {
		previewURL = utils.BuildPreviewURL(*sm.FilePreview)
	}
	return dto.SuratMasukResponse{
		ID:               sm.ID,
		NoSurat:          sm.NoSurat,
		Perihal:          sm.PerihalSurat,
		AsalSurat:        sm.AsalSurat,
		Status:           utils.MapStatusDisplay(sm.StatusVerifikasi),
		StatusVerifikasi: sm.StatusVerifikasi,
		StatusAlur:       sm.StatusAlur,
		FileURL:          fileURL,
		PreviewURL:       previewURL,
		TotalPages:       0,   // diisi oleh buildResponseWithPages
		Pages:            nil, // diisi oleh buildResponseWithPages
		CreatedAt:        sm.CreatedAt,
	}
}

// notifyKepsekSuratBaru mengirim notifikasi ke semua kepsek saat surat masuk baru.
func (s *SuratMasukService) notifyKepsekSuratBaru(pengirimID uint, sm *models.SuratMasuk) {
	ids, _ := s.users.FindIDsByLevelAkses(utils.LevelKepsek)
	p := pengirimID
	for _, uid := range ids {
		if uid == pengirimID {
			continue
		}
		_ = s.notif.Create(CreateNotificationInput{
			PenerimaID:  uid,
			PengirimID:  &p,
			Type:        NotifTypeSuratMasuk,
			Title:       "Surat masuk baru",
			Message:     "Surat " + sm.NoSurat + " menunggu verifikasi",
			ReferenceID: sm.ID,
		})
	}
}

// notifyAdminsVerifikasi mengirim notifikasi ke admin setelah kepsek memverifikasi surat.
func (s *SuratMasukService) notifyAdminsVerifikasi(kepsekID uint, sm *models.SuratMasuk, approved bool) {
	ids, _ := s.users.FindIDsByLevelAkses(utils.LevelAdmin)
	p := kepsekID
	msg := "Surat " + sm.NoSurat + " ditolak"
	if approved {
		msg = "Surat " + sm.NoSurat + " disetujui"
	}
	for _, uid := range ids {
		_ = s.notif.Create(CreateNotificationInput{
			PenerimaID:  uid,
			PengirimID:  &p,
			Type:        NotifTypeApproval,
			Title:       "Verifikasi surat masuk",
			Message:     msg,
			ReferenceID: sm.ID,
			Rejected:    !approved,
		})
	}
}
