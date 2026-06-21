package learningseed

import (
	"embed"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

//go:embed sql/*.sql
var sqlFS embed.FS

var userLookupBlock020 = `DECLARE
    admin_id UUID;
    owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(owner_email))
    LIMIT 1;

    IF admin_id IS NULL THEN
        RAISE NOTICE 'Owner % not found — skip learning/interview seed', owner_email;
        RETURN;
    END IF;`

var userLookupBlock022 = `DECLARE
    admin_id UUID;
    owner_email TEXT := 'mphuc8671@gmail.com';
BEGIN
    SELECT id INTO admin_id FROM users
    WHERE lower(trim(email)) = lower(trim(owner_email)) LIMIT 1;
    IF admin_id IS NULL THEN
        RAISE NOTICE 'Owner % not found — skip DSA program seed', owner_email;
        RETURN;
    END IF;`

func RunBootstrapSQL(db *gorm.DB, userID uuid.UUID) error {
	files := []string{
		"sql/020_learning.sql",
		"sql/022_dsa.sql",
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
	return reassignLearningSeed(db, userID)
}

func patchUserID(sql string, userID uuid.UUID) string {
	replacement := fmt.Sprintf(`DECLARE
    admin_id UUID := '%s'::uuid;
BEGIN`, userID)
	for _, block := range []string{userLookupBlock020, userLookupBlock022} {
		if strings.Contains(sql, block) {
			sql = strings.Replace(sql, block, replacement, 1)
		}
	}
	return sql
}
