package services

import (
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/models"
	"github.com/fiorelln/disposisi/repositories"
	"gorm.io/gorm"
)

var ErrNotificationNotFound = errors.New("notifikasi tidak ditemukan")

const (
	NotifTypeSuratMasuk  = "surat_masuk"
	NotifTypeSuratKeluar = "surat_keluar"
	NotifTypeDisposisi   = "disposisi"
	NotifTypeApproval    = "approval"
	NotifTypeDistribusi  = "distribusi"
	NotifTypeSystem      = "system"
)

type CreateNotificationInput struct {
	PenerimaID  uint
	PengirimID  *uint
	Type        string
	Title       string
	Message     string
	ReferenceID uint
	Rejected    bool // for approval → surat_ditolak jenis
}

type NotificationService struct {
	repo *repositories.NotificationRepository
}

func NewNotificationService(repo *repositories.NotificationRepository) *NotificationService {
	return &NotificationService{repo: repo}
}

func (s *NotificationService) Create(input CreateNotificationInput) error {
	n := s.buildModel(input)
	return s.repo.Create(n)
}

func (s *NotificationService) CreateWithTx(tx *gorm.DB, input CreateNotificationInput) error {
	n := s.buildModel(input)
	return s.repo.WithTx(tx).Create(n)
}

func (s *NotificationService) GetNotifications(penerimaID uint, q dto.NotificationListQuery) (*dto.NotificationListData, error) {
	page, limit := normalizePageLimit(q.Page, q.Limit)

	list, total, err := s.repo.List(repositories.NotificationListParams{
		PenerimaID: penerimaID,
		Page:       page,
		Limit:      limit,
		UnreadOnly: q.UnreadOnly,
		Type:       q.Type,
	})
	if err != nil {
		return nil, err
	}

	unread, err := s.repo.CountUnread(penerimaID)
	if err != nil {
		return nil, err
	}

	items := make([]dto.NotificationResponse, 0, len(list))
	for i := range list {
		items = append(items, mapNotificationResponse(&list[i]))
	}

	return &dto.NotificationListData{
		Items:       items,
		Page:        page,
		Limit:       limit,
		Total:       total,
		UnreadCount: unread,
	}, nil
}

func (s *NotificationService) MarkAsRead(id, penerimaID uint) (*dto.NotificationResponse, error) {
	_, err := s.repo.FindByIDForPenerima(id, penerimaID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, ErrNotificationNotFound
		}
		return nil, err
	}

	now := time.Now()
	if err := s.repo.MarkAsRead(id, penerimaID, now); err != nil {
		return nil, err
	}

	n, err := s.repo.FindByIDForPenerima(id, penerimaID)
	if err != nil {
		return nil, err
	}
	resp := mapNotificationResponse(n)
	return &resp, nil
}

func (s *NotificationService) CountUnread(penerimaID uint) (int64, error) {
	return s.repo.CountUnread(penerimaID)
}

func (s *NotificationService) buildModel(input CreateNotificationInput) *models.Notifikasi {
	jenis := mapNotifTypeToDBJenis(input.Type, input.Rejected)
	tipe := input.Type
	link := buildNotifLinkURL(input.Type, input.ReferenceID)
	pesan := input.Message
	pengirim := input.PengirimID

	return &models.Notifikasi{
		PenerimaID:    input.PenerimaID,
		PengirimID:    pengirim,
		Jenis:         &jenis,
		Judul:         input.Title,
		Pesan:         &pesan,
		LinkURL:       &link,
		TipeReferensi: &tipe,
		IsRead:        false,
	}
}

func mapNotifTypeToDBJenis(apiType string, rejected bool) string {
	switch apiType {
	case NotifTypeSuratMasuk:
		return "surat_masuk_baru"
	case NotifTypeSuratKeluar:
		return "surat_keluar_baru"
	case NotifTypeDisposisi:
		return "surat_masuk_dikonfirmasi"
	case NotifTypeApproval:
		if rejected {
			return "surat_ditolak"
		}
		return "surat_disetujui"
	case NotifTypeDistribusi:
		return "surat_keluar_dikonfirmasi"
	case NotifTypeSystem:
		return "permintaan_persetujuan_akun"
	default:
		return "surat_masuk_baru"
	}
}

func buildNotifLinkURL(notifType string, refID uint) string {
	if refID == 0 {
		return notifType
	}
	return fmt.Sprintf("%s/%d", notifType, refID)
}

func parseReferenceID(linkURL *string) uint {
	if linkURL == nil || *linkURL == "" {
		return 0
	}
	parts := strings.Split(strings.Trim(*linkURL, "/"), "/")
	if len(parts) == 0 {
		return 0
	}
	last := parts[len(parts)-1]
	id, err := strconv.ParseUint(last, 10, 32)
	if err != nil {
		return 0
	}
	return uint(id)
}

func mapNotificationResponse(n *models.Notifikasi) dto.NotificationResponse {
	msg := ""
	if n.Pesan != nil {
		msg = *n.Pesan
	}
	tipe := ""
	if n.TipeReferensi != nil {
		tipe = *n.TipeReferensi
	}
	return dto.NotificationResponse{
		ID:          n.ID,
		Title:       n.Judul,
		Message:     msg,
		Type:        tipe,
		IsRead:      n.IsRead,
		ReferenceID: parseReferenceID(n.LinkURL),
		CreatedAt:   n.CreatedAt,
	}
}

func normalizePageLimit(page, limit int) (int, int) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 20
	}
	if limit > 100 {
		limit = 100
	}
	return page, limit
}
