package learningseed

import (
	"fmt"
	"log"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

const OwnerEmail = "mphuc8671@gmail.com"

func IsOwnerEmail(email string) bool {
	return strings.EqualFold(strings.TrimSpace(email), OwnerEmail)
}

// SyncForUser reassigns learning curriculum to the Fash JWT user_id and bootstraps if empty.
func SyncForUser(db *gorm.DB, userID uuid.UUID, email string) error {
	if !IsOwnerEmail(email) {
		return nil
	}
	return ensureOwnerLearning(db, userID)
}

func ensureOwnerLearning(db *gorm.DB, userID uuid.UUID) error {
	if HasSeedCurriculum(db, userID) {
		log.Printf("learningseed: owner %s curriculum OK", userID)
		return nil
	}
	log.Printf("learningseed: bootstrapping learning curriculum for owner %s", userID)
	if err := EnsureForUser(db, userID); err != nil {
		return fmt.Errorf("learningseed bootstrap: %w", err)
	}
	var count int64
	_ = db.Model(&models.Entity{}).
		Where("user_id = ? AND domain = ? AND status = ?", userID, models.DomainLearning, "active").
		Count(&count)
	log.Printf("learningseed: after bootstrap owner has %d learning entities", count)
	return nil
}

func reassignLearningSeed(db *gorm.DB, userID uuid.UUID) error {
	if err := db.Exec(`
		UPDATE entities SET user_id = ?, updated_at = NOW()
		WHERE source IN ('learning_seed', 'interview_seed')
	`, userID).Error; err != nil {
		return err
	}
	return db.Exec(`
		UPDATE entities SET user_id = ?, updated_at = NOW()
		WHERE domain = 'learning' AND id::text LIKE 'c000000c-0001-4001-8001-%'
	`, userID).Error
}
