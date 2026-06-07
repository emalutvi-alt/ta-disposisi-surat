package helpers

import (
	"golang.org/x/crypto/bcrypt"
)

// CheckPassword verifies password against bcrypt hash.
// If stored value is not a bcrypt hash (legacy seed data), falls back to plain comparison.
func CheckPassword(hash string, password string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// HashPassword hashes password with bcrypt.
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}
