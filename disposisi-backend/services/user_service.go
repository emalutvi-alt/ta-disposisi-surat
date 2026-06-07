package services

import (
	"github.com/fiorelln/disposisi/dto"
	"github.com/fiorelln/disposisi/repositories"
	"github.com/fiorelln/disposisi/utils"
)

type UserService struct {
	users *repositories.UserRepository
}

func NewUserService(users *repositories.UserRepository) *UserService {
	return &UserService{users: users}
}

// ListDisposisiTargets returns staff eligible as disposisi recipients (user/pegawai level).
func (s *UserService) ListDisposisiTargets() ([]dto.UserBriefResponse, error) {
	list, err := s.users.ListDisposisiTargets()
	if err != nil {
		return nil, err
	}
	out := make([]dto.UserBriefResponse, 0, len(list))
	for i := range list {
		jabatan := ""
		for _, uj := range list[i].UserJabatans {
			if uj.Jabatan.NamaJabatan != "" {
				jabatan = uj.Jabatan.NamaJabatan
				if uj.IsPrimary {
					break
				}
			}
		}
		level := utils.LevelUser
		if len(list[i].UserJabatans) > 0 {
			level = utils.NormalizeLevelAkses(list[i].UserJabatans[0].Jabatan.LevelAkses)
		}
		out = append(out, dto.UserBriefResponse{
			ID:      list[i].ID,
			Nama:    list[i].Name,
			Email:   list[i].Email,
			Jabatan: jabatan,
			Role:    utils.MapLevelToFlutter(level),
		})
	}
	return out, nil
}
