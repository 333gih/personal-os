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
	if err := reassignLearningSeed(db, userID); err != nil {
		return err
	}

	var count int64
	if err := db.Model(&models.Entity{}).
		Where("user_id = ? AND domain = ? AND status = ?", userID, models.DomainLearning, "active").
		Count(&count).Error; err != nil {
		return err
	}
	if count >= 20 {
		log.Printf("learningseed: owner %s has %d learning entities", userID, count)
		return nil
	}

	var globalSeed int64
	if err := db.Model(&models.Entity{}).
		Where("source IN ? OR id::text LIKE ?", []string{"learning_seed", "interview_seed"}, "c000000c-0001-4001-8001-%").
		Count(&globalSeed).Error; err != nil {
		return err
	}

	if globalSeed > 0 {
		_ = reassignLearningSeed(db, userID)
		db.Model(&models.Entity{}).
			Where("user_id = ? AND domain = ? AND status = ?", userID, models.DomainLearning, "active").
			Count(&count)
		if count >= 20 {
			return nil
		}
	}

	log.Printf("learningseed: bootstrapping learning curriculum for owner %s", userID)
	if err := RunBootstrapSQL(db, userID); err != nil {
		return fmt.Errorf("learningseed bootstrap: %w", err)
	}

	if err := db.Model(&models.Entity{}).
		Where("user_id = ? AND domain = ? AND status = ?", userID, models.DomainLearning, "active").
		Count(&count).Error; err != nil {
		return err
	}
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
