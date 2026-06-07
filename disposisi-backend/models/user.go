package models

import "time"

// User maps to PostgreSQL table users.
type User struct {
	ID        uint      `gorm:"primaryKey;column:id_user" json:"id"`
	Name      string    `gorm:"column:nama;not null" json:"name"`
	Email     string    `gorm:"column:email;unique;not null" json:"email"`
	Password  string    `gorm:"column:password;not null" json:"-"`
	CreatedAt time.Time `gorm:"column:created_at" json:"created_at"`

	UserJabatans []UserJabatan `gorm:"foreignKey:UserID;references:ID" json:"user_jabatans,omitempty"`
}

func (User) TableName() string {
	return "users"
}
