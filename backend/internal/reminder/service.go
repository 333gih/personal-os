package reminder

import (
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

type Service struct {
	db *gorm.DB
}

type CreateInput struct {
	EntityID uuid.UUID `json:"entity_id" binding:"required"`
	Title    string    `json:"title" binding:"required"`
	DueAt    time.Time `json:"due_at" binding:"required"`
}

func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

func (s *Service) Create(userID uuid.UUID, input CreateInput) (*models.Reminder, error) {
	var entity models.Entity
	if err := s.db.Where("id = ? AND user_id = ?", input.EntityID, userID).First(&entity).Error; err != nil {
		return nil, err
	}
	reminder := models.Reminder{
		UserID:   userID,
		EntityID: input.EntityID,
		Title:    input.Title,
		DueAt:    input.DueAt,
		Status:   "pending",
	}
	if err := s.db.Create(&reminder).Error; err != nil {
		return nil, err
	}
	return &reminder, nil
}

func (s *Service) List(userID uuid.UUID, status string) ([]models.Reminder, error) {
	q := s.db.Where("user_id = ?", userID)
	if status != "" {
		q = q.Where("status = ?", status)
	}
	var reminders []models.Reminder
	err := q.Order("due_at ASC").Find(&reminders).Error
	return reminders, err
}

func (s *Service) Upcoming(userID uuid.UUID, days int) ([]models.Reminder, error) {
	if days <= 0 {
		days = 7
	}
	until := time.Now().AddDate(0, 0, days)
	var reminders []models.Reminder
	err := s.db.Where("user_id = ? AND status = 'pending' AND due_at <= ?", userID, until).
		Order("due_at ASC").Find(&reminders).Error
	return reminders, err
}

func (s *Service) Complete(userID, id uuid.UUID) error {
	now := time.Now()
	result := s.db.Model(&models.Reminder{}).
		Where("id = ? AND user_id = ?", id, userID).
		Updates(map[string]any{"status": "completed", "completed_at": now})
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return result.Error
}

func (s *Service) Delete(userID, id uuid.UUID) error {
	result := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Reminder{})
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return result.Error
}
