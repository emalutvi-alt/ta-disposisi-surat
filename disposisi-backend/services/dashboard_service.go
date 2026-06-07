package services

import (
	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
)

type DashboardService struct {
	dash *repositories.DashboardRepository
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
