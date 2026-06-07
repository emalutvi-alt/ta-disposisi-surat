package repositories

import (
	"github.com/fiorelln/disposisi/models"
	"gorm.io/gorm"
)

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) FindByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.
		Preload("UserJabatans.Jabatan").
		Where("email = ?", email).
		First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) FindByID(id uint) (*models.User, error) {
	var user models.User
	err := r.db.
		Preload("UserJabatans.Jabatan").
		Where("id_user = ?", id).
		First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *UserRepository) UpdatePassword(userID uint, hashedPassword string) error {
	return r.db.Model(&models.User{}).
		Where("id_user = ?", userID).
		Update("password", hashedPassword).Error
}

func (r *UserRepository) FindIDsByLevelAkses(level string) ([]uint, error) {
	var ids []uint
	err := r.db.Model(&models.User{}).
		Distinct("users.id_user").
		Joins("JOIN user_jabatan uj ON uj.id_user = users.id_user").
		Joins("JOIN jabatan j ON j.id_jabatan = uj.id_jabatan").
		Where("j.level_akses = ?", level).
		Pluck("users.id_user", &ids).Error
	return ids, err
}

// FindIDsByJabatanName - cari user IDs berdasarkan nama jabatan (untuk disposisi)
func (r *UserRepository) FindIDsByJabatanName(jabatanName string) ([]uint, error) {
	var ids []uint
	err := r.db.Model(&models.User{}).
		Distinct("users.id_user").
		Joins("JOIN user_jabatan uj ON uj.id_user = users.id_user").
		Joins("JOIN jabatan j ON j.id_jabatan = uj.id_jabatan").
		Where("j.nama_jabatan ILIKE ?", "%"+jabatanName+"%").
		Pluck("users.id_user", &ids).Error
	if err != nil {
		return nil, err
	}
	return ids, nil
}

func (r *UserRepository) CountByIDs(ids []uint) (int64, error) {
	if len(ids) == 0 {
		return 0, nil
	}
	var count int64
	err := r.db.Model(&models.User{}).Where("id_user IN ?", ids).Count(&count).Error
	return count, err
}

func (r *UserRepository) ListDisposisiTargets() ([]models.User, error) {
	var ids []uint
	err := r.db.Model(&models.User{}).
		Distinct().
		Joins("JOIN user_jabatan uj ON uj.id_user = users.id_user").
		Joins("JOIN jabatan j ON j.id_jabatan = uj.id_jabatan").
		Where("j.level_akses IN ?", []string{"user", "pegawai"}).
		Pluck("users.id_user", &ids).Error
	if err != nil {
		return nil, err
	}
	if len(ids) == 0 {
		return []models.User{}, nil
	}
	var users []models.User
	err = r.db.
		Preload("UserJabatans.Jabatan").
		Where("id_user IN ?", ids).
		Order("nama ASC").
		Find(&users).Error
	return users, err
}
