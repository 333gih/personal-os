package entity

import (
	"encoding/json"
	"errors"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/embedding"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

type Service struct {
	db     *gorm.DB
	ai     *ai.Service
	embed  *embedding.Service
}

type CreateInput struct {
	Type     string         `json:"type" binding:"required"`
	Title    string         `json:"title" binding:"required"`
	Content  string         `json:"content"`
	Tags     []string       `json:"tags"`
	Source   string         `json:"source"`
	Metadata map[string]any `json:"metadata"`
}

type UpdateInput struct {
	Title    *string        `json:"title"`
	Content  *string        `json:"content"`
	Tags     []string       `json:"tags"`
	Source   *string        `json:"source"`
	Metadata map[string]any `json:"metadata"`
	Status   *string        `json:"status"`
	Type     *string        `json:"type"`
}

type ListFilter struct {
	Domain string
	Type   string
	Tag    string
	Status string
	Limit  int
	Offset int
}

type DetailResponse struct {
	Entity    models.Entity           `json:"entity"`
	Relations []RelationWithEntity    `json:"relations"`
	Reminders []models.Reminder       `json:"reminders"`
	Timeline  []TimelineEvent         `json:"timeline"`
	Insights  *ai.AnalyzeResult       `json:"insights,omitempty"`
}

type RelationWithEntity struct {
	models.Relationship
	RelatedEntity models.Entity `json:"related_entity"`
	Direction     string        `json:"direction"`
}

type TimelineEvent struct {
	Type      string    `json:"type"`
	Title     string    `json:"title"`
	Timestamp string    `json:"timestamp"`
	Meta      any       `json:"meta,omitempty"`
}

func NewService(db *gorm.DB, aiSvc *ai.Service, embedSvc *embedding.Service) *Service {
	return &Service{db: db, ai: aiSvc, embed: embedSvc}
}

// entityReads omits pgvector embedding — not needed for API responses and costly on list/detail.
func entityReads(db *gorm.DB) *gorm.DB {
	return db.Omit("embedding")
}

func (s *Service) Create(userID uuid.UUID, input CreateInput) (*models.Entity, error) {
	tagsJSON, _ := json.Marshal(input.Tags)
	if input.Tags == nil {
		tagsJSON = []byte("[]")
	}
	meta := input.Metadata
	if meta == nil {
		meta = map[string]any{}
	}

	entity := models.Entity{
		UserID:   userID,
		Type:     input.Type,
		Title:    input.Title,
		Content:  input.Content,
		Tags:     tagsJSON,
		Source:   input.Source,
		Metadata: meta,
		Domain:   models.DomainForType(input.Type),
		Status:   "active",
	}

	if err := s.db.Create(&entity).Error; err != nil {
		return nil, err
	}

	if s.embed != nil {
		s.embed.EnqueueEntity(userID, &entity)
	}
	return &entity, nil
}

func (s *Service) Get(userID, id uuid.UUID) (*models.Entity, error) {
	var entity models.Entity
	err := entityReads(s.db).Where("id = ? AND user_id = ?", id, userID).First(&entity).Error
	return &entity, err
}

func (s *Service) List(userID uuid.UUID, f ListFilter) ([]models.Entity, int64, error) {
	q := s.db.Model(&models.Entity{}).Where("user_id = ?", userID)
	if f.Domain != "" {
		q = q.Where("domain = ?", f.Domain)
	}
	if f.Type != "" {
		q = q.Where("type = ?", f.Type)
	}
	if f.Status != "" {
		q = q.Where("status = ?", f.Status)
	}
	if f.Tag != "" {
		q = q.Where("tags @> ?", `["`+f.Tag+`"]`)
	}

	var total int64
	if err := q.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	limit := f.Limit
	if limit <= 0 || limit > 200 {
		limit = 20
	}

	var entities []models.Entity
	err := entityReads(q).Order("updated_at DESC").Limit(limit).Offset(f.Offset).Find(&entities).Error
	return entities, total, err
}

func (s *Service) Update(userID, id uuid.UUID, input UpdateInput) (*models.Entity, error) {
	entity, err := s.Get(userID, id)
	if err != nil {
		return nil, err
	}

	if input.Title != nil {
		entity.Title = *input.Title
	}
	if input.Content != nil {
		entity.Content = *input.Content
	}
	if input.Tags != nil {
		tagsJSON, _ := json.Marshal(input.Tags)
		entity.Tags = tagsJSON
	}
	if input.Source != nil {
		entity.Source = *input.Source
	}
	if input.Metadata != nil {
		entity.Metadata = input.Metadata
	}
	if input.Status != nil {
		entity.Status = *input.Status
	}
	if input.Type != nil {
		entity.Type = *input.Type
		entity.Domain = models.DomainForType(*input.Type)
	}

	if err := s.db.Save(entity).Error; err != nil {
		return nil, err
	}

	if s.embed != nil {
		s.embed.EnqueueEntity(userID, entity)
	}
	return entity, nil
}

func (s *Service) Delete(userID, id uuid.UUID) error {
	result := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&models.Entity{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	s.db.Where("user_id = ? AND (source_entity_id = ? OR target_entity_id = ?)", userID, id, id).Delete(&models.Relationship{})
	if s.embed != nil {
		s.embed.RemoveIndex(models.SourceTableEntities, id)
	}
	return nil
}

func (s *Service) GetDetail(userID, id uuid.UUID, includeInsights bool) (*DetailResponse, error) {
	entity, err := s.Get(userID, id)
	if err != nil {
		return nil, err
	}

	var relations []models.Relationship
	s.db.Where("user_id = ? AND (source_entity_id = ? OR target_entity_id = ?)", userID, id, id).
		Order("created_at DESC").Find(&relations)

	relatedIDs := make([]uuid.UUID, 0, len(relations))
	for _, r := range relations {
		if r.SourceEntityID == id {
			relatedIDs = append(relatedIDs, r.TargetEntityID)
		} else {
			relatedIDs = append(relatedIDs, r.SourceEntityID)
		}
	}

	entityMap := map[uuid.UUID]models.Entity{}
	if len(relatedIDs) > 0 {
		var related []models.Entity
		entityReads(s.db).Where("id IN ?", relatedIDs).Find(&related)
		for _, e := range related {
			entityMap[e.ID] = e
		}
	}

	relWithEntities := make([]RelationWithEntity, 0, len(relations))
	for _, r := range relations {
		rwe := RelationWithEntity{Relationship: r}
		if r.SourceEntityID == id {
			rwe.Direction = "outgoing"
			rwe.RelatedEntity = entityMap[r.TargetEntityID]
		} else {
			rwe.Direction = "incoming"
			rwe.RelatedEntity = entityMap[r.SourceEntityID]
		}
		relWithEntities = append(relWithEntities, rwe)
	}

	var reminders []models.Reminder
	s.db.Where("user_id = ? AND entity_id = ?", userID, id).Order("due_at ASC").Find(&reminders)

	timeline := []TimelineEvent{
		{Type: "created", Title: "Entity created", Timestamp: entity.CreatedAt.Format("2006-01-02T15:04:05Z07:00")},
	}
	if entity.UpdatedAt.After(entity.CreatedAt) {
		timeline = append(timeline, TimelineEvent{
			Type: "updated", Title: "Entity updated",
			Timestamp: entity.UpdatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}
	for _, r := range relWithEntities {
		timeline = append(timeline, TimelineEvent{
			Type: "relation", Title: r.RelationType + " → " + r.RelatedEntity.Title,
			Timestamp: r.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
		})
	}

	resp := &DetailResponse{
		Entity:    *entity,
		Relations: relWithEntities,
		Reminders: reminders,
		Timeline:  timeline,
	}

	if includeInsights && s.ai != nil {
		insights, err := s.ai.Analyze(userID, entity)
		if err == nil {
			resp.Insights = insights
		}
	}

	return resp, nil
}

func (s *Service) CountByDomain(userID uuid.UUID) (map[string]int64, error) {
	type row struct {
		Domain string
		Count  int64
	}
	var rows []row
	err := s.db.Model(&models.Entity{}).
		Select("domain, count(*) as count").
		Where("user_id = ? AND status = 'active'", userID).
		Group("domain").
		Scan(&rows).Error
	if err != nil {
		return nil, err
	}
	out := map[string]int64{}
	for _, r := range rows {
		out[r.Domain] = r.Count
	}
	return out, nil
}

func (s *Service) Recent(userID uuid.UUID, limit int) ([]models.Entity, error) {
	if limit <= 0 {
		limit = 10
	}
	var entities []models.Entity
	err := entityReads(s.db).Where("user_id = ?", userID).Order("updated_at DESC").Limit(limit).Find(&entities).Error
	return entities, err
}

func IsNotFound(err error) bool {
	return errors.Is(err, gorm.ErrRecordNotFound)
}
