package relation

import (
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

type Service struct {
	db *gorm.DB
}

type CreateInput struct {
	SourceEntityID uuid.UUID `json:"source_entity_id" binding:"required"`
	TargetEntityID uuid.UUID `json:"target_entity_id" binding:"required"`
	RelationType   string    `json:"relation_type" binding:"required"`
}

func NewService(db *gorm.DB) *Service {
	return &Service{db: db}
}

func (s *Service) Create(userID uuid.UUID, input CreateInput) (*models.Relationship, error) {
	if input.SourceEntityID == input.TargetEntityID {
		return nil, gorm.ErrInvalidData
	}

	var count int64
	s.db.Model(&models.Entity{}).Where("id IN ? AND user_id = ?", []uuid.UUID{input.SourceEntityID, input.TargetEntityID}, userID).Count(&count)
	if count != 2 {
		return nil, gorm.ErrRecordNotFound
	}

	rel := models.Relationship{
		UserID:         userID,
		SourceEntityID: input.SourceEntityID,
		TargetEntityID: input.TargetEntityID,
		RelationType:   input.RelationType,
	}
	if err := s.db.Create(&rel).Error; err != nil {
		return nil, err
	}
	return &rel, nil
}

func (s *Service) List(userID uuid.UUID, entityID *uuid.UUID) ([]models.Relationship, error) {
	q := s.db.Where("user_id = ?", userID)
	if entityID != nil {
		q = q.Where("source_entity_id = ? OR target_entity_id = ?", *entityID, *entityID)
	}
	var rels []models.Relationship
	err := q.Order("created_at DESC").Find(&rels).Error
	return rels, err
}

func (s *Service) Delete(userID, id uuid.UUID) error {
	result := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Relationship{})
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return result.Error
}
