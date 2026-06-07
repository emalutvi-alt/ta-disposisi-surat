package helpers

import "time"

// TokenBlacklist revokes JWT tokens (future-ready; stateless logout returns success today).
type TokenBlacklist interface {
	Add(token string, expiresAt time.Time) error
	IsBlacklisted(token string) bool
}

// NoopTokenBlacklist is a no-op implementation until Redis/DB blacklist is added.
type NoopTokenBlacklist struct{}

func NewNoopTokenBlacklist() *NoopTokenBlacklist {
	return &NoopTokenBlacklist{}
}

func (b *NoopTokenBlacklist) Add(_ string, _ time.Time) error {
	return nil
}

func (b *NoopTokenBlacklist) IsBlacklisted(_ string) bool {
	return false
}
