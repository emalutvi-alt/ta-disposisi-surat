package services

import (
	"errors"
	"fmt"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
	"gorm.io/gorm"
)

type UnifiedService struct {
	db              *gorm.DB
	suratMasukRepo  *repositories.SuratMasukRepository
	suratKeluarRepo *repositories.SuratKeluarRepository
	disposisiRepo   *repositories.DisposisiRepository
	userRepo        *repositories.UserRepository
	notifSvc        *NotificationService
	logSvc          *LogService
}

func NewUnifiedService(
	db *gorm.DB,
	suratMasukRepo *repositories.SuratMasukRepository,
	suratKeluarRepo *repositories.SuratKeluarRepository,
	disposisiRepo *repositories.DisposisiRepository,
	userRepo *repositories.UserRepository,
	notifSvc *NotificationService,
	logSvc *LogService,
) *UnifiedService {
	return &UnifiedService{
		db:              db,
		suratMasukRepo:  suratMasukRepo,
		suratKeluarRepo: suratKeluarRepo,
		disposisiRepo:   disposisiRepo,
		userRepo:        userRepo,
		notifSvc:        notifSvc,
		logSvc:          logSvc,
	}
}

// ProcessSuratMasukDisposisi - Kepsek approve/reject + disposisi
func (s *UnifiedService) ProcessSuratMasukDisposisi(
	kepsekID uint,
	idSuratMasuk uint,
	req dto.UnifiedDisposisiRequest,
) (*dto.UnifiedDisposisiResponse, error) {
	surat, err := s.suratMasukRepo.FindByID(idSuratMasuk)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}

	if surat.StatusVerifikasi != "menunggu" {
		return nil, errors.New("surat sudah diproses sebelumnya")
	}

	now := time.Now()
	catatan := req.Catatan

	if req.Status == "disetujui" {
		// Approve
		surat.StatusVerifikasi = "disetujui"
		surat.StatusAlur = "diteruskan"
		surat.UserVerifikasi = &kepsekID
		surat.TanggalVerifikasi = &now
		if catatan != "" {
			surat.CatatanVerifikasi = &catatan
		}

		if err := s.suratMasukRepo.Update(surat); err != nil {
			return nil, err
		}

		// Create disposisi for each tujuan (by jabatan name → user IDs)
		for _, tujuanNama := range req.Tujuan {
			userIDs, err := s.userRepo.FindIDsByJabatanName(tujuanNama)
			if err != nil {
				continue
			}
			
			for _, uid := range userIDs {
				// Cek duplicate
				exists, _ := s.disposisiRepo.ExistsForSuratAndPenerima(idSuratMasuk, uid)
				if exists {
					continue
				}

				disposisi := models.Disposisi{
					SuratMasukID:         idSuratMasuk,
					KepsekID:             kepsekID,
					PenerimaID:           uid,
					Catatan:              &catatan,
					TanggapanSaran:       &req.TanggapanSaran,
					ProsesLanjut:         &req.ProsesLanjut,
					KoordinasiKonfirmasi: &req.KoordinasiKonfirmasi,
					TanggalDisposisi:     now,
					StatusDisposisi:      "belum_dibaca",
					StatusApproval:       "disetujui",
				}
				
				if err := s.disposisiRepo.CreateBatch([]models.Disposisi{disposisi}); err != nil {
					continue
				}
				_ = s.notifSvc.Create(CreateNotificationInput{
					PenerimaID:  uid,
					PengirimID:  &kepsekID,
					Type:        NotifTypeDisposisi,
					Title:       "Disposisi Baru",
					Message:     fmt.Sprintf("Anda menerima disposisi surat dari %s", surat.AsalSurat),
					ReferenceID: idSuratMasuk,
				})
			}
		}

		s.logSvc.WriteAuditLog(AuditLogInput{
			UserID:   &kepsekID,
			Action:   AuditVerifySuratMasuk,
			Table:    "surat_masuk",
			RecordID: &surat.ID,
			OldValue: "menunggu",
			NewValue: "disetujui",
		})

		return &dto.UnifiedDisposisiResponse{
			IDSurat:              idSuratMasuk,
			Status:               "disetujui",
			Catatan:              req.Catatan,
			Tujuan:               req.Tujuan,
			TanggapanSaran:       req.TanggapanSaran,
			ProsesLanjut:         req.ProsesLanjut,
			KoordinasiKonfirmasi: req.KoordinasiKonfirmasi,
			TanggalDisposisi:     now,
			DiteruskanKe:         fmt.Sprintf("%v", req.Tujuan),
		}, nil

	} else {
		// Reject
		surat.StatusVerifikasi = "ditolak"
		surat.StatusAlur = "ditolak"
		surat.UserVerifikasi = &kepsekID
		surat.TanggalVerifikasi = &now
		if catatan != "" {
			surat.CatatanVerifikasi = &catatan
		}

		if err := s.suratMasukRepo.Update(surat); err != nil {
			return nil, err
		}

		tuIDs, _ := s.userRepo.FindIDsByLevelAkses(utils.LevelAdmin)
		for _, tuID := range tuIDs {
			_ = s.notifSvc.Create(CreateNotificationInput{
				PenerimaID:  tuID,
				PengirimID:  &kepsekID,
				Type:        NotifTypeApproval,
				Title:       "Surat Masuk Ditolak",
				Message:     fmt.Sprintf("Surat %s ditolak: %s", surat.NoSurat, catatan),
				ReferenceID: idSuratMasuk,
				Rejected:    true,
			})
		}

		s.logSvc.WriteAuditLog(AuditLogInput{
			UserID:   &kepsekID,
			Action:   AuditVerifySuratMasuk,
			Table:    "surat_masuk",
			RecordID: &surat.ID,
			OldValue: "menunggu",
			NewValue: "ditolak",
		})

		return &dto.UnifiedDisposisiResponse{
			IDSurat:          idSuratMasuk,
			Status:           "ditolak",
			Catatan:          req.Catatan,
			TanggalDisposisi: now,
		}, nil
	}
}

// ProcessSuratKeluarVerifikasi - Kepsek approve/reject surat keluar
func (s *UnifiedService) ProcessSuratKeluarVerifikasi(
	kepsekID uint,
	idSuratKeluar uint,
	req dto.UnifiedDisposisiRequest,
) (*dto.UnifiedDisposisiResponse, error) {
	surat, err := s.suratKeluarRepo.FindByID(idSuratKeluar)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrSuratNotFound
		}
		return nil, err
	}

	if surat.StatusVerifikasi != "menunggu" {
		return nil, errors.New("surat sudah diproses sebelumnya")
	}

	now := time.Now()
	catatan := req.Catatan

	if req.Status == "disetujui" {
		surat.StatusVerifikasi = "disetujui"
		surat.StatusAlur = "diteruskan"
		surat.UserVerifikasi = &kepsekID
		surat.TanggalVerifikasi = &now
		if catatan != "" {
			surat.CatatanVerifikasi = &catatan
		}

		if err := s.suratKeluarRepo.Update(surat); err != nil {
			return nil, err
		}

		// Create distribusi untuk tujuan (by jabatan name)
		distriRepo := repositories.NewDistribusiSKRepository(s.db)
		for _, tujuanNama := range req.Tujuan {
			userIDs, err := s.userRepo.FindIDsByJabatanName(tujuanNama)
			if err != nil {
				continue
			}
			
			for _, uid := range userIDs {
				distribusi := models.DistribusiSK{
					SuratKeluarID: idSuratKeluar,
					UserID:        uid,
					Status:        "belum_dibaca",
					DistributeAt:  now,
				}
				if err := distriRepo.CreateBatch([]models.DistribusiSK{distribusi}); err != nil {
					continue
				}
				
				_ = s.notifSvc.Create(CreateNotificationInput{
					PenerimaID:  uid,
					PengirimID:  &kepsekID,
					Type:        NotifTypeDistribusi,
					Title:       "Surat Keluar Baru",
					Message:     fmt.Sprintf("Anda menerima surat keluar %s", surat.NoSurat),
					ReferenceID: idSuratKeluar,
				})
			}
		}

		s.logSvc.WriteAuditLog(AuditLogInput{
			UserID:   &kepsekID,
			Action:   AuditVerifySuratKeluar,
			Table:    "surat_keluar",
			RecordID: &surat.ID,
			OldValue: "menunggu",
			NewValue: "disetujui",
		})

		return &dto.UnifiedDisposisiResponse{
			IDSurat:          idSuratKeluar,
			Status:           "disetujui",
			Catatan:          req.Catatan,
			Tujuan:           req.Tujuan,
			TanggalDisposisi: now,
		}, nil

	} else {
		surat.StatusVerifikasi = "ditolak"
		surat.StatusAlur = "ditolak"
		surat.UserVerifikasi = &kepsekID
		surat.TanggalVerifikasi = &now
		if catatan != "" {
			surat.CatatanVerifikasi = &catatan
		}

		if err := s.suratKeluarRepo.Update(surat); err != nil {
			return nil, err
		}

		tuIDs, _ := s.userRepo.FindIDsByLevelAkses(utils.LevelAdmin)
		for _, tuID := range tuIDs {
			_ = s.notifSvc.Create(CreateNotificationInput{
				PenerimaID:  tuID,
				PengirimID:  &kepsekID,
				Type:        NotifTypeApproval,
				Title:       "Surat Keluar Ditolak",
				Message:     fmt.Sprintf("Surat %s ditolak: %s", surat.NoSurat, catatan),
				ReferenceID: idSuratKeluar,
				Rejected:    true,
			})
		}

		s.logSvc.WriteAuditLog(AuditLogInput{
			UserID:   &kepsekID,
			Action:   AuditVerifySuratKeluar,
			Table:    "surat_keluar",
			RecordID: &surat.ID,
			OldValue: "menunggu",
			NewValue: "ditolak",
		})

		return &dto.UnifiedDisposisiResponse{
			IDSurat:          idSuratKeluar,
			Status:           "ditolak",
			Catatan:          req.Catatan,
			TanggalDisposisi: now,
		}, nil
	}
}

// MarkSuratAsRead - User tandai surat dibaca
func (s *UnifiedService) MarkSuratAsRead(
	userID uint,
	idSurat uint,
	jenis string,
) error {
	now := time.Now()

	if jenis == "masuk" {
		return s.db.Model(&models.DistribusiSM{}).
			Where("id_user = ? AND id_disposisi IN (SELECT id_disposisi FROM disposisi WHERE id_surat_masuk = ?)", 
				userID, idSurat).
			Updates(map[string]interface{}{
				"status":  "dibaca",
				"read_at": now,
			}).Error
	} else {
		return s.db.Model(&models.DistribusiSK{}).
			Where("id_user = ? AND id_sk = ?", userID, idSurat).
			Updates(map[string]interface{}{
				"status":  "dibaca",
				"read_at": now,
			}).Error
	}
}
