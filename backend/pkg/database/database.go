package database

import (
	"fmt"

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

	if err := db.AutoMigrate(
		&models.User{},
		&models.Entity{},
		&models.Relationship{},
		&models.Reminder{},
		&models.File{},
	); err != nil {
		return nil, fmt.Errorf("auto migrate: %w", err)
	}

	return db, nil
}
