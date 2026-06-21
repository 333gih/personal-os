package startupseed

import (
	"log"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

const OwnerEmail = "mphuc8671@gmail.com"

// SyncForUser seeds Fash startup portfolio for the owner account.
func SyncForUser(db *gorm.DB, userID uuid.UUID, email string) error {
	if !strings.EqualFold(strings.TrimSpace(email), OwnerEmail) {
		return nil
	}
	var count int64
	if err := db.Model(&models.Entity{}).
		Where("user_id = ? AND domain = ? AND status = ?", userID, models.DomainStartup, "active").
		Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		log.Printf("startupseed: owner has %d startup entities", count)
		return nil
	}
	// Migration 019 seeds on first deploy; if empty, log hint.
	log.Printf("startupseed: no startup entities for owner — run migrations/019_fash_startup_seed.sql")
	return nil
}
