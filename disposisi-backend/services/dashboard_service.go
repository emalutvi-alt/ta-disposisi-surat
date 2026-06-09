package services

import (
	"errors"
	"time"

	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
)

type DashboardService struct {
	dash  *repositories.DashboardRepository
	notif *NotificationService
}

func NewDashboardService(dash *repositories.DashboardRepository, notif *NotificationService) *DashboardService {
	return &DashboardService{dash: dash, notif: notif}
}

func (s *DashboardService) GetStats(userID uint, level string) (*dto.DashboardStatsResponse, error) {
	sm, err := s.dash.CountSuratMasuk()
	if err != nil {
		return nil, err
	}
	sk, err := s.dash.CountSuratKeluar()
	if err != nil {
		return nil, err
	}
	disp, err := s.dash.CountDisposisi()
	if err != nil {
		return nil, err
	}
	selesai, err := s.dash.CountSuratSelesai()
	if err != nil {
		return nil, err
	}
	unread, err := s.notif.CountUnread(userID)
	if err != nil {
		return nil, err
	}

	var pending int64
	switch level {
	case utils.LevelKepsek:
		pending, err = s.dash.CountPendingSuratVerifikasi()
	case utils.LevelUser:
		pending, err = s.dash.CountPendingDisposisiForUser(userID)
	default:
		pending, err = s.dash.CountPendingSuratVerifikasi()
	}
	if err != nil {
		return nil, err
	}

	return &dto.DashboardStatsResponse{
		TotalSuratMasuk:     sm,
		TotalSuratKeluar:    sk,
		TotalDisposisi:      disp,
		UnreadNotifications: unread,
		PendingApproval:     pending,
		SuratSelesai:        selesai,
	}, nil
}

func (s *DashboardService) ListAktif(userID uint, role string) (*dto.DashboardListData, error) {
	var (
		items []dto.DashboardSuratItem
		err   error
	)
	switch role {
	case utils.FlutterTU:
		items, err = s.dash.ListAktifTU()
	case utils.FlutterKepsek:
		items, err = s.dash.ListAktifKepsek()
	case utils.FlutterUsers:
		wakaItems, wakaErr := s.dash.ListAktifWaka(userID)
		if wakaErr != nil {
			return nil, wakaErr
		}
		userItems, userErr := s.dash.ListAktifUser(userID)
		if userErr != nil {
			return nil, userErr
		}
		items = append(wakaItems, userItems...)
	default:
		return nil, errors.New("role tidak valid")
	}
	if err != nil {
		return nil, err
	}
	normalizeDashboardItems(items)
	return &dto.DashboardListData{Items: items, Total: len(items)}, nil
}

func (s *DashboardService) ListRiwayat(userID uint, role string, q dto.RiwayatFilterQuery) (*dto.DashboardListData, error) {
	dateRange, err := buildRiwayatDateRange(q)
	if err != nil {
		return nil, err
	}

	var items []dto.DashboardSuratItem
	switch role {
	case utils.FlutterTU:
		items, err = s.dash.ListRiwayatTU(dateRange)
	case utils.FlutterKepsek:
		items = []dto.DashboardSuratItem{}
	case utils.FlutterUsers:
		wakaItems, wakaErr := s.dash.ListRiwayatWaka(userID, dateRange)
		if wakaErr != nil {
			return nil, wakaErr
		}
		userItems, userErr := s.dash.ListRiwayatUser(userID, dateRange)
		if userErr != nil {
			return nil, userErr
		}
		items = append(wakaItems, userItems...)
	default:
		return nil, errors.New("role tidak valid")
	}
	if err != nil {
		return nil, err
	}
	normalizeDashboardItems(items)
	return &dto.DashboardListData{Items: items, Total: len(items)}, nil
}

func buildRiwayatDateRange(q dto.RiwayatFilterQuery) (repositories.RiwayatDateRange, error) {
	if q.Tanggal != "" {
		t, err := time.Parse("2006-01-02", q.Tanggal)
		if err != nil {
			return repositories.RiwayatDateRange{}, errors.New("format tanggal harus YYYY-MM-DD")
		}
		return repositories.RiwayatDateRange{Start: &t, End: &t}, nil
	}

	now := time.Now()
	var start, end time.Time
	switch q.Filter {
	case "", "semua":
		return repositories.RiwayatDateRange{}, nil
	case "hari_ini":
		start = time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		end = start
	case "minggu_ini":
		weekday := int(now.Weekday())
		if weekday == 0 {
			weekday = 7
		}
		start = time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location()).AddDate(0, 0, -(weekday - 1))
		end = start.AddDate(0, 0, 6)
	case "bulan_ini":
		start = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		end = start.AddDate(0, 1, -1)
	default:
		return repositories.RiwayatDateRange{}, errors.New("filter riwayat tidak valid")
	}
	return repositories.RiwayatDateRange{Start: &start, End: &end}, nil
}

func normalizeDashboardItems(items []dto.DashboardSuratItem) {
	for i := range items {
		if items[i].PreviewURL != "" {
			items[i].PreviewURL = utils.BuildPreviewURL(items[i].PreviewURL)
		}
	}
}
