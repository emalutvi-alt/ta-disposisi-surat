package services

import (
	"errors"
	"strings"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
	"gorm.io/gorm"
)

var (
	ErrDisposisiNotFound   = errors.New("disposisi tidak ditemukan")
	ErrDisposisiForbidden  = errors.New("akses disposisi ditolak")
	ErrSuratBelumDisetujui = errors.New("surat masuk harus disetujui kepsek sebelum disposisi")
	ErrDuplicatePenerima   = errors.New("penerima sudah memiliki disposisi untuk surat ini")
	ErrInvalidTujuan       = errors.New("satu atau lebih penerima tidak valid")
	ErrDisposisiStatus     = errors.New("status disposisi tidak dapat diubah")
)

type DisposisiService struct {
	db          *gorm.DB
	disposisi   *repositories.DisposisiRepository
	distribusi  *repositories.DistribusiSMRepository
	suratMasuk  *repositories.SuratMasukRepository
	userRepo    *repositories.UserRepository
	logSvc      *LogService
	notif       *NotificationService
}

func NewDisposisiService(
	db *gorm.DB,
	disposisi *repositories.DisposisiRepository,
	distribusi *repositories.DistribusiSMRepository,
	suratMasuk *repositories.SuratMasukRepository,
	userRepo *repositories.UserRepository,
	logSvc *LogService,
	notif *NotificationService,
) *DisposisiService {
	return &DisposisiService{
		db:         db,
		disposisi:  disposisi,
		distribusi: distribusi,
		suratMasuk: suratMasuk,
		userRepo:   userRepo,
		logSvc:     logSvc,
		notif:      notif,
	}
}

func mapDisposisiResponse(d *models.Disposisi) dto.DisposisiResponse {
	catatan := ""
	if d.Catatan != nil {
		catatan = *d.Catatan
	}

	suratNo := ""
	perihal := ""
	previewURL := ""
	if d.SuratMasuk.ID != 0 {
		suratNo = d.SuratMasuk.NoSurat
		perihal = d.SuratMasuk.PerihalSurat
		if d.SuratMasuk.FilePreview != nil {
			previewURL = utils.BuildPreviewURL(*d.SuratMasuk.FilePreview)
		}
	}

	penerimaName := ""
	if d.Penerima.ID != 0 {
		penerimaName = d.Penerima.Name
	}

	status := utils.MapDisposisiStatusToAPI(d.StatusDisposisi, d.StatusApproval)

	batasWaktu := ""
	if d.ProsesLanjut != nil && strings.HasPrefix(*d.ProsesLanjut, "batas:") {
		parts := strings.SplitN(*d.ProsesLanjut, ";", 2)
		if len(parts) > 0 {
			batasWaktu = strings.TrimPrefix(parts[0], "batas:")
		}
	}

	return dto.DisposisiResponse{
		ID:                 d.ID,
		SuratID:            d.SuratMasukID,
		SuratNo:            suratNo,
		Perihal:            perihal,
		Tujuan: dto.DisposisiTujuanResponse{
			ID:   d.PenerimaID,
			Nama: penerimaName,
		},
		Status:             status,
		VerificationStatus: d.StatusApproval,
		Catatan:            catatan,
		PreviewURL:         previewURL,
		BatasWaktu:         batasWaktu,
		CreatedAt:          d.TanggalDisposisi,
	}
}

func (s *DisposisiService) Create(userID uint, req dto.CreateDisposisiRequest) (*dto.CreateDisposisiResult, error) {
	_, err := s.suratMasuk.FindByID(req.SuratMasukID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrDisposisiNotFound
		}
		return nil, err
	}

	creator, err := s.userRepo.FindByID(userID)
	if err != nil {
		return nil, ErrDisposisiForbidden
	}

	creatorRole := getUserRole(creator)
	statusApproval := "menunggu"
	if creatorRole == utils.FlutterKepsek {
		statusApproval = "disetujui"
	}

	var createdRows []models.Disposisi
	now := time.Now()

	for _, tID := range req.TujuanIDs {
		penerima, err := s.userRepo.FindByID(tID)
		if err != nil || penerima == nil {
			return nil, ErrInvalidTujuan
		}

		exists, _ := s.disposisi.ExistsForSuratAndPenerima(req.SuratMasukID, tID)
		if exists {
			return nil, ErrDuplicatePenerima
		}

		prosesLanjut := req.ProsesLanjut
		if req.BatasWaktu != "" {
			prosesLanjut = "batas:" + req.BatasWaktu + ";" + req.ProsesLanjut
		}

		catatan := req.Catatan
		tanggapan := req.TanggapanSaran
		koordinasi := req.KoordinasiKonfirmasi

		row := models.Disposisi{
			SuratMasukID:         req.SuratMasukID,
			KepsekID:             userID,
			PenerimaID:           tID,
			Catatan:              &catatan,
			TanggapanSaran:       &tanggapan,
			ProsesLanjut:         &prosesLanjut,
			KoordinasiKonfirmasi: &koordinasi,
			TanggalDisposisi:     now,
			StatusDisposisi:      "belum_dibaca",
			StatusApproval:       statusApproval,
		}
		createdRows = append(createdRows, row)
	}

	if err := s.disposisi.CreateBatch(createdRows); err != nil {
		return nil, err
	}

	// Fetch created rows to load relationships for mapping
	var items []dto.DisposisiResponse
	for _, row := range createdRows {
		fullRow, err := s.disposisi.FindByID(row.ID)
		if err == nil {
			items = append(items, mapDisposisiResponse(fullRow))
		}
	}

	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID:   &userID,
		Action:   AuditCreateDisposisi,
		Table:    "disposisi",
		RecordID: nil,
	})

	return &dto.CreateDisposisiResult{
		Created: len(items),
		Items:   items,
	}, nil
}

func (s *DisposisiService) List(filter dto.DisposisiFilter, userID uint, role string) ([]dto.DisposisiResponse, error) {
	var scopePenerimaID *uint
	if role == utils.FlutterUsers {
		scopePenerimaID = &userID
	}

	list, err := s.disposisi.List(filter, scopePenerimaID)
	if err != nil {
		return nil, err
	}

	out := make([]dto.DisposisiResponse, 0, len(list))
	for i := range list {
		out = append(out, mapDisposisiResponse(&list[i]))
	}
	return out, nil
}

func (s *DisposisiService) ListBySurat(suratID uint) ([]dto.DisposisiResponse, error) {
	list, err := s.disposisi.FindBySuratMasukID(suratID)
	if err != nil {
		return nil, err
	}

	out := make([]dto.DisposisiResponse, 0, len(list))
	for i := range list {
		out = append(out, mapDisposisiResponse(&list[i]))
	}
	return out, nil
}

func (s *DisposisiService) Approve(userID, disposisiID uint, isApproved bool, catatan string) error {
	d, err := s.disposisi.FindByID(disposisiID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrDisposisiNotFound
		}
		return err
	}

	status := "ditolak"
	if isApproved {
		status = "disetujui"
	}

	d.StatusApproval = status
	now := time.Now()
	d.ApprovalAt = &now
	if catatan != "" {
		d.Catatan = &catatan
	}

	if err := s.disposisi.Update(d); err != nil {
		return err
	}

	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID:   &userID,
		Action:   AuditApproveDisposisi,
		Table:    "disposisi",
		RecordID: &d.ID,
		OldValue: "menunggu",
		NewValue: status,
	})

	return nil
}

func (s *DisposisiService) MarkSelesai(userID, disposisiID uint) error {
	d, err := s.disposisi.FindByID(disposisiID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrDisposisiNotFound
		}
		return err
	}

	if d.PenerimaID != userID {
		return ErrDisposisiForbidden
	}

	d.StatusDisposisi = "selesai"
	if err := s.disposisi.Update(d); err != nil {
		return err
	}

	s.logSvc.WriteAuditLog(AuditLogInput{
		UserID:   &userID,
		Action:   "complete_disposisi",
		Table:    "disposisi",
		RecordID: &d.ID,
	})

	return nil
}

func (s *DisposisiService) GetByID(level string, userID, disposisiID uint) (*dto.DisposisiResponse, error) {
	d, err := s.disposisi.FindByID(disposisiID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrDisposisiNotFound
		}
		return nil, err
	}

	if level == utils.LevelUser && d.PenerimaID != userID {
		return nil, ErrDisposisiForbidden
	}
	if level == utils.LevelKepsek && d.KepsekID != userID && d.PenerimaID != userID {
		return nil, ErrDisposisiForbidden
	}

	resp := mapDisposisiResponse(d)
	return &resp, nil
}

func (s *DisposisiService) MarkRead(userID, disposisiID uint) error {
	d, err := s.disposisi.FindByID(disposisiID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return ErrDisposisiNotFound
		}
		return err
	}

	if d.PenerimaID != userID {
		return ErrDisposisiForbidden
	}

	now := time.Now()
	if err := s.distribusi.MarkRead(d.ID, userID, now); err != nil {
		return err
	}

	if d.StatusDisposisi == "belum_dibaca" {
		d.StatusDisposisi = "dibaca"
		if err := s.disposisi.Update(d); err != nil {
			return err
		}
	}

	return nil
}
