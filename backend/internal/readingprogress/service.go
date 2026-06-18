package readingprogress

import (
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type Service struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

type SaveInput struct {
	StoryID            string         `json:"story_id" binding:"required"`
	StoryTitle         string         `json:"story_title" binding:"required"`
	ChapterID          string         `json:"chapter_id"`
	ChapterTitle       string         `json:"chapter_title"`
	CurrentURL         string         `json:"current_url"`
	Progress           ProgressInput  `json:"progress" binding:"required"`
	Metadata           map[string]any `json:"metadata"`
	ClientTimestamp    int64          `json:"client_timestamp"`
}

type ProgressInput struct {
	Percentage         int `json:"percentage"`
	ScrollY            int `json:"scroll_y"`
	ReadingTimeSeconds int `json:"reading_time_seconds"`
}

func (s *Service) Save(userID uuid.UUID, input SaveInput) (*models.ReadingProgress, error) {
	now := time.Now()
	clientTS := now
	if input.ClientTimestamp > 0 {
		clientTS = time.UnixMilli(input.ClientTimestamp)
	}

	siteID := "generic"
	if input.Metadata != nil {
		if v, ok := input.Metadata["parser"].(string); ok && v != "" {
			siteID = v
		}
	}

	row := models.ReadingProgress{
		UserID:             userID,
		StoryID:            input.StoryID,
		StoryTitle:         input.StoryTitle,
		ChapterID:          input.ChapterID,
		ChapterTitle:       input.ChapterTitle,
		CurrentURL:         input.CurrentURL,
		ProgressPercentage: input.Progress.Percentage,
		ScrollY:            input.Progress.ScrollY,
		ReadingTimeSeconds: input.Progress.ReadingTimeSeconds,
		SiteID:             siteID,
		Metadata:           datatypes.JSONMap(input.Metadata),
		ClientTimestamp:    &clientTS,
		LastReadAt:         now,
	}

	err := s.db.Where(
		"user_id = ? AND story_id = ?",
		userID, input.StoryID,
	).Assign(map[string]any{
		"chapter_id":           row.ChapterID,
		"chapter_title":        row.ChapterTitle,
		"story_title":          row.StoryTitle,
		"current_url":          row.CurrentURL,
		"progress_percentage":  row.ProgressPercentage,
		"scroll_y":             row.ScrollY,
		"reading_time_seconds": row.ReadingTimeSeconds,
		"site_id":              row.SiteID,
		"metadata":             row.Metadata,
		"client_timestamp":     row.ClientTimestamp,
		"last_read_at":         row.LastReadAt,
		"updated_at":           now,
	}).FirstOrCreate(&row).Error
	if err != nil {
		return nil, err
	}

	_ = s.db.Where("user_id = ? AND story_id = ? AND id <> ?", userID, input.StoryID, row.ID).
		Delete(&models.ReadingProgress{}).Error

	return &row, nil
}

func (s *Service) ListCurrent(userID uuid.UUID, limit int) ([]models.ReadingProgress, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	var items []models.ReadingProgress
	err := s.db.Where("user_id = ?", userID).
		Order("last_read_at DESC").
		Limit(limit).
		Find(&items).Error
	return items, err
}
