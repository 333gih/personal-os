package learningseed

import (
	"log"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

const OwnerEmail = "mphuc8671@gmail.com"

func SyncForUser(db *gorm.DB, userID uuid.UUID, email string) error {
	if !strings.EqualFold(strings.TrimSpace(email), OwnerEmail) {
		return nil
	}
	var count int64
	if err := db.Model(&models.Entity{}).
		Where("user_id = ? AND domain = ? AND source = ?", userID, models.DomainLearning, "learning_seed").
		Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		log.Printf("learningseed: owner has %d learning seed entities", count)
		return nil
	}
	log.Printf("learningseed: no learning seed — run migrations/020, 021, 022 on server")
	return nil
}
