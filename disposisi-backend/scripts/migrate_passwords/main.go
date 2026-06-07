package main

import (
	"fmt"
	"log"
	"strings"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type UserRow struct {
	ID       uint
	Password string
}

func isBcryptHash(h string) bool {
	return strings.HasPrefix(h, "$2a$") ||
		strings.HasPrefix(h, "$2b$") ||
		strings.HasPrefix(h, "$2y$")
}

func main() {
	dsn := "host=localhost user=postgres password=postgres12345 dbname=disposisi_surat sslmode=disable"
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal(err)
	}

	var users []UserRow
	db.Raw("SELECT id_user AS id, password FROM users").Scan(&users)

	migrated := 0
	for _, u := range users {
		if isBcryptHash(u.Password) {
			continue // sudah bcrypt, skip
		}
		// Password ini masih plaintext — hash sekarang
		hashed, err := bcrypt.GenerateFromPassword([]byte(u.Password), bcrypt.DefaultCost)
		if err != nil {
			log.Printf("SKIP user %d: %v", u.ID, err)
			continue
		}
		db.Exec("UPDATE users SET password = ? WHERE id_user = ?", string(hashed), u.ID)
		fmt.Printf("Migrated user %d\n", u.ID)
		migrated++
	}
	fmt.Printf("Done. %d users migrated.\n", migrated)
}
