package database

import (
	"fmt"
	"os"

	"github.com/personal-os/backend/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

func Connect(dsn string, appEnv string) (*gorm.DB, error) {
	logLevel := logger.Info
	if appEnv == "production" {
		logLevel = logger.Warn
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logLevel),
	})
	if err != nil {
		return nil, fmt.Errorf("connect database: %w", err)
	}

	// Schema is managed by SQL migrations in production/Jenkins. AutoMigrate is opt-in for local dev.
	if os.Getenv("DB_AUTO_MIGRATE") == "true" {
		if err := db.AutoMigrate(
			&models.User{},
			&models.Entity{},
			&models.Relationship{},
			&models.Reminder{},
			&models.File{},
			&models.ReadingProgress{},
			&models.EmbeddingJob{},
			&models.AIInteraction{},
			&models.ModelUsage{},
		); err != nil {
			return nil, fmt.Errorf("auto migrate: %w", err)
		}
	}

	return db, nil
}
