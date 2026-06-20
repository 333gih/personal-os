package workseed

import (
	"embed"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

//go:embed sql/*.sql
var sqlFS embed.FS

var userLookupBlock008 = `DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE EXCEPTION 'Career owner % not found. Log in to Personal OS once with this email (Fash Auth), then re-run this migration.', career_owner_email;
    END IF;`

var userLookupBlock009 = `DECLARE
    admin_id UUID;
    career_owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(career_owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE EXCEPTION 'Career owner % not found. Log in once with this email, then re-run migrations/010_work_career_all.sql', career_owner_email;
    END IF;`

func RunBootstrapSQL(db *gorm.DB, userID uuid.UUID) error {
	files := []string{
		"sql/012_functions.sql",
		"sql/008_career.sql",
		"sql/009_design.sql",
	}
	for _, name := range files {
		raw, err := sqlFS.ReadFile(name)
		if err != nil {
			return fmt.Errorf("read %s: %w", name, err)
		}
		query := patchUserID(string(raw), userID)
		if err := db.Exec(query).Error; err != nil {
			return fmt.Errorf("exec %s: %w", name, err)
		}
	}
	if err := runDesignPatch(db); err != nil {
		return fmt.Errorf("design patch: %w", err)
	}
	return reassignCareerSeed(db, userID)
}

func runDesignPatch(db *gorm.DB) error {
	raw, err := sqlFS.ReadFile("sql/013_fpt_architecture.sql")
	if err != nil {
		return fmt.Errorf("read 013: %w", err)
	}
	return db.Exec(string(raw)).Error
}

func patchUserID(sql string, userID uuid.UUID) string {
	replacement := fmt.Sprintf(`DECLARE
    admin_id UUID := '%s'::uuid;
BEGIN`, userID)
	for _, block := range []string{userLookupBlock008, userLookupBlock009} {
		if strings.Contains(sql, block) {
			return strings.Replace(sql, block, replacement, 1)
		}
	}
	return strings.ReplaceAll(sql, "__USER_ID__", userID.String())
}
