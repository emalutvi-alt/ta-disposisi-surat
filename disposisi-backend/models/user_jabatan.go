package models

// UserJabatan maps to PostgreSQL table user_jabatan (composite PK).
type UserJabatan struct {
	UserID    uint `gorm:"primaryKey;column:id_user" json:"user_id"`
	JabatanID uint `gorm:"primaryKey;column:id_jabatan" json:"jabatan_id"`
	IsPrimary bool `gorm:"column:is_primary" json:"is_primary"`

	User    User    `gorm:"foreignKey:UserID;references:ID" json:"user,omitempty"`
	Jabatan Jabatan `gorm:"foreignKey:JabatanID;references:ID" json:"jabatan,omitempty"`
}

func (UserJabatan) TableName() string {
	return "user_jabatan"
}
