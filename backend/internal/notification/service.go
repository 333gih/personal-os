package notification

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/pkg/config"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

type Service struct {
	db  *gorm.DB
	pub *Publisher
	cfg config.NotificationConfig
}

func NewService(db *gorm.DB, pub *Publisher, cfg config.NotificationConfig) *Service {
	return &Service{db: db, pub: pub, cfg: cfg}
}

type SendInput struct {
	UserID         uuid.UUID
	Title          string
	Body           string
	Type           string
	DeepLink       string
	IdempotencyKey string
	Priority       string
	Channel        string
}

func (s *Service) Send(ctx context.Context, in SendInput) (*models.NotificationLog, error) {
	if in.Channel == "" {
		in.Channel = "push"
	}
	if in.Priority == "" {
		in.Priority = "normal"
	}

	if in.IdempotencyKey != "" {
		var existing models.NotificationLog
		err := s.db.Where("user_id = ? AND idempotency_key = ?", in.UserID, in.IdempotencyKey).First(&existing).Error
		if err == nil {
			return &existing, nil
		}
		if err != gorm.ErrRecordNotFound {
			return nil, err
		}
	}

	payload := map[string]string{
		"type": in.Type,
	}
	if in.DeepLink != "" {
		payload["deep_link"] = in.DeepLink
	}

	logEntry := models.NotificationLog{
		UserID:         in.UserID,
		Channel:        in.Channel,
		Title:          in.Title,
		Body:           in.Body,
		Status:         "queued",
		IdempotencyKey: in.IdempotencyKey,
	}
	logEntry.Payload = datatypes.JSONMap{}
	for k, v := range payload {
		logEntry.Payload[k] = v
	}

	if err := s.db.Create(&logEntry).Error; err != nil {
		return nil, err
	}

	if !s.cfg.Enabled || !s.pub.Enabled() {
		_ = s.db.Model(&logEntry).Update("status", "logged_only").Error
		logEntry.Status = "logged_only"
		return &logEntry, nil
	}

	if s.inQuietHours(in.UserID) && in.Priority != "high" {
		_ = s.db.Model(&logEntry).Updates(map[string]any{
			"status":        "skipped",
			"error_message": "quiet hours",
		}).Error
		logEntry.Status = "skipped"
		return &logEntry, nil
	}

	event := NewRequestedEvent(
		[]string{in.UserID.String()},
		in.Title,
		in.Body,
		s.cfg.DefaultLocale,
		in.Priority,
		payload,
		in.IdempotencyKey,
	)

	if err := s.pub.Publish(ctx, event); err != nil {
		msg := err.Error()
		_ = s.db.Model(&logEntry).Updates(map[string]any{"status": "failed", "error_message": msg}).Error
		logEntry.Status = "failed"
		logEntry.ErrorMessage = msg
		return &logEntry, fmt.Errorf("kafka publish: %w", err)
	}

	_ = s.db.Model(&logEntry).Update("status", "sent").Error
	logEntry.Status = "sent"
	return &logEntry, nil
}

func (s *Service) List(userID uuid.UUID, limit int) ([]models.NotificationLog, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	var rows []models.NotificationLog
	err := s.db.Where("user_id = ?", userID).Order("created_at DESC").Limit(limit).Find(&rows).Error
	return rows, err
}

func (s *Service) inQuietHours(userID uuid.UUID) bool {
	var sched models.LearningSchedule
	if err := s.db.Where("user_id = ?", userID).First(&sched).Error; err != nil {
		return s.isQuietHour(time.Now())
	}
	loc, err := time.LoadLocation(sched.Timezone)
	if err != nil {
		loc = time.UTC
	}
	return s.isQuietHour(time.Now().In(loc))
}

func (s *Service) isQuietHour(t time.Time) bool {
	h := t.Hour()
	start := s.cfg.QuietStartHour
	end := s.cfg.QuietEndHour
	if start == end {
		return false
	}
	if start > end {
		return h >= start || h < end
	}
	return h >= start && h < end
}
