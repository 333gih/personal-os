package learningseed

import (
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

const (
	SeedIDPrefix     = "c000000c-0001-4001-8001-"
	anchorPatternID  = "c000000c-0001-4001-8001-000000000003" // Two Pointers
	anchorEnglishID  = "c000000c-0001-4001-8001-000000000023" // English course
)

func IsSeedEntityID(id uuid.UUID) bool {
	return strings.HasPrefix(strings.ToLower(id.String()), SeedIDPrefix)
}

func HasSeedCurriculum(db *gorm.DB, userID uuid.UUID) bool {
	var patterns, english int64
	db.Model(&models.Entity{}).
		Where("user_id = ? AND id = ? AND domain = ? AND status = 'active'", userID, anchorPatternID, models.DomainLearning).
		Count(&patterns)
	db.Model(&models.Entity{}).
		Where("user_id = ? AND id = ? AND domain = ? AND status = 'active'", userID, anchorEnglishID, models.DomainLearning).
		Count(&english)
	return patterns > 0 && english > 0
}

// EnsureForUser attaches seed rows to userID and bootstraps when DSA/English anchors are missing.
func EnsureForUser(db *gorm.DB, userID uuid.UUID) error {
	if err := reassignLearningSeed(db, userID); err != nil {
		return err
	}
	if HasSeedCurriculum(db, userID) {
		return nil
	}

	var global int64
	if err := db.Model(&models.Entity{}).
		Where("domain = ? AND id::text LIKE ?", models.DomainLearning, SeedIDPrefix+"%").
		Count(&global).Error; err != nil {
		return err
	}
	if global > 0 {
		_ = reassignLearningSeed(db, userID)
		if HasSeedCurriculum(db, userID) {
			return nil
		}
	}

	return RunBootstrapSQL(db, userID)
}
