package workseed

import (
	"fmt"
	"log"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

// OwnerEmail is the Fash Auth account that owns career template data.
const OwnerEmail = "mphuc8671@gmail.com"

// SyncForUser reassigns career data to the owner and seeds if the database has none.
// Called after Fash Auth login so user_id matches the JWT.
func SyncForUser(db *gorm.DB, userID uuid.UUID, email string) error {
	if !IsOwnerEmail(email) {
		return nil
	}
	return ensureOwnerCareer(db, userID)
}

func IsOwnerEmail(email string) bool {
	return strings.EqualFold(strings.TrimSpace(email), OwnerEmail)
}

func ensureOwnerCareer(db *gorm.DB, userID uuid.UUID) error {
	if err := reassignCareerSeed(db, userID); err != nil {
		return err
	}

	if err := runDesignPatch(db); err != nil {
		log.Printf("workseed: fpt architecture patch: %v", err)
	}

	var workCount int64
	if err := db.Model(&models.Entity{}).
		Where("user_id = ? AND domain = ? AND status = ?", userID, models.DomainWork, "active").
		Count(&workCount).Error; err != nil {
		return err
	}

	if workCount > 0 {
		log.Printf("workseed: owner %s has %d work entities", userID, workCount)
		return nil
	}

	var globalSeed int64
	if err := db.Model(&models.Entity{}).Where("source = ?", "career_seed").Count(&globalSeed).Error; err != nil {
		return err
	}

	if globalSeed > 0 {
		// Data exists but still 0 for user — force reassign again
		if err := reassignCareerSeed(db, userID); err != nil {
			return err
		}
		db.Model(&models.Entity{}).
			Where("user_id = ? AND domain = ? AND status = ?", userID, models.DomainWork, "active").
			Count(&workCount)
		if workCount > 0 {
			return nil
		}
	}

	log.Printf("workseed: seeding career data for owner %s", userID)
	if err := RunBootstrapSQL(db, userID); err != nil {
		return fmt.Errorf("workseed bootstrap: %w", err)
	}

	if err := db.Model(&models.Entity{}).
		Where("user_id = ? AND domain = ? AND status = ?", userID, models.DomainWork, "active").
		Count(&workCount).Error; err != nil {
		return err
	}
	log.Printf("workseed: after bootstrap owner has %d work entities", workCount)
	return nil
}

func reassignCareerSeed(db *gorm.DB, userID uuid.UUID) error {
	if err := db.Exec(`UPDATE entities SET user_id = ?, updated_at = NOW() WHERE source = 'career_seed'`, userID).Error; err != nil {
		return err
	}

	// Legacy MVP seed rows tied to admin@personal-os.local
	return db.Exec(`
		UPDATE entities e SET user_id = ?, updated_at = NOW()
		FROM users u
		WHERE e.user_id = u.id AND u.email = 'admin@personal-os.local'
		  AND e.domain IN ('work', 'learning', 'startup', 'inbox')
	`, userID).Error
}
