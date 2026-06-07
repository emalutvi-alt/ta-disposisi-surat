package models

import "time"

// Log maps to PostgreSQL table log (audit aktivitas).
type Log struct {
	ID           uint      `gorm:"primaryKey;column:id_log" json:"id"`
	UserID       *uint     `gorm:"column:id_user" json:"id_user,omitempty"`
	Aksi         *string   `gorm:"column:aksi" json:"aksi,omitempty"`
	TabelTerkait *string   `gorm:"column:tabel_terkait" json:"tabel_terkait,omitempty"`
	KolomTerkait *string   `gorm:"column:kolom_terkait" json:"kolom_terkait,omitempty"`
	IDData       *int      `gorm:"column:id_data" json:"id_data,omitempty"`
	ValuesOld    *string   `gorm:"column:values_old" json:"values_old,omitempty"`
	ValuesNew    *string   `gorm:"column:values_new" json:"values_new,omitempty"`
	UpdatedAt    time.Time `gorm:"column:updated_at" json:"updated_at"`

	User *User `gorm:"foreignKey:UserID;references:ID" json:"user,omitempty"`
}

func (Log) TableName() string {
	return "log"
}
