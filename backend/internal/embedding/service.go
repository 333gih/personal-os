package embedding

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/infrastructure/qdrant"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Service struct {
	db     *gorm.DB
	ai     *ai.Service
	qdrant *qdrant.Client
	cfg    WorkerConfig
}

type WorkerConfig struct {
	Enabled      bool
	Interval     time.Duration
	MaxAttempts  int
	VectorSize   int
}

func NewService(db *gorm.DB, aiSvc *ai.Service, qdrantClient *qdrant.Client, cfg WorkerConfig) *Service {
	return &Service{db: db, ai: aiSvc, qdrant: qdrantClient, cfg: cfg}
}

func (s *Service) EnqueueEntity(userID uuid.UUID, entity *models.Entity) {
	s.enqueue(userID, models.SourceTableEntities, models.AIEntityType(entity.Domain, entity.Type), entity.ID)
}

func (s *Service) EnqueueReadingProgress(userID uuid.UUID, rowID uuid.UUID) {
	s.enqueue(userID, models.SourceTableReadingProgress, models.AITypeBook, rowID)
}

func (s *Service) enqueue(userID uuid.UUID, sourceTable, entityType string, entityID uuid.UUID) {
	job := models.EmbeddingJob{
		UserID:      userID,
		SourceTable: sourceTable,
		EntityType:  entityType,
		EntityID:    entityID,
		Status:      models.EmbeddingJobPending,
		Attempts:    0,
	}
	err := s.db.Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "source_table"}, {Name: "entity_id"}},
		DoUpdates: clause.Assignments(map[string]any{
			"status":        models.EmbeddingJobPending,
			"attempts":      0,
			"last_error":    "",
			"processed_at":  nil,
			"entity_type":   entityType,
			"user_id":       userID,
		}),
	}).Create(&job).Error
	if err != nil {
		log.Printf("embedding: enqueue %s/%s: %v", sourceTable, entityID, err)
	}
}

func (s *Service) RemoveIndex(sourceTable string, entityID uuid.UUID) {
	ctx := context.Background()
	if s.qdrant != nil && s.qdrant.Enabled() {
		_ = s.qdrant.Delete(ctx, entityID)
	}
	_ = s.db.Where("source_table = ? AND entity_id = ?", sourceTable, entityID).
		Delete(&models.EmbeddingJob{}).Error
}

func (s *Service) StartWorker(ctx context.Context) {
	if !s.cfg.Enabled {
		log.Printf("embedding: worker disabled")
		return
	}
	if s.qdrant != nil && s.qdrant.Enabled() {
		if err := s.qdrant.EnsureCollection(ctx); err != nil {
			log.Printf("embedding: qdrant ensure collection: %v", err)
		} else {
			log.Printf("embedding: qdrant collection ready")
		}
	}
	ticker := time.NewTicker(s.cfg.Interval)
	defer ticker.Stop()
	log.Printf("embedding: worker started (interval=%s)", s.cfg.Interval)
	for {
		select {
		case <-ctx.Done():
			log.Printf("embedding: worker stopped")
			return
		case <-ticker.C:
			s.processBatch(ctx)
		}
	}
}

func (s *Service) processBatch(ctx context.Context) {
	if s.ai == nil {
		return
	}
	var jobs []models.EmbeddingJob
	err := s.db.Where("status = ? AND attempts < ?", models.EmbeddingJobPending, s.cfg.MaxAttempts).
		Order("created_at ASC").
		Limit(10).
		Find(&jobs).Error
	if err != nil || len(jobs) == 0 {
		return
	}
	for _, job := range jobs {
		s.processJob(ctx, job)
	}
}

func (s *Service) processJob(ctx context.Context, job models.EmbeddingJob) {
	now := time.Now()
	s.db.Model(&job).Updates(map[string]any{
		"status":   models.EmbeddingJobProcessing,
		"attempts": gorm.Expr("attempts + 1"),
	})
	job.Attempts++

	content, err := s.loadContent(job.SourceTable, job.EntityID)
	if err != nil {
		s.failJob(&job, err)
		return
	}

	text := strings.TrimSpace(content.Title + "\n" + content.Content)
	if text == "" {
		s.completeJob(&job, now)
		return
	}

	vec, err := s.ai.EmbedForUser(job.UserID, "embed", text)
	if err != nil {
		s.failJob(&job, err)
		return
	}

	if job.SourceTable == models.SourceTableEntities {
		if err := s.db.Model(&models.Entity{}).
			Where("id = ?", job.EntityID).
			Update("embedding", vec).Error; err != nil {
			s.failJob(&job, err)
			return
		}
	}

	if s.qdrant != nil && s.qdrant.Enabled() {
		tags := parseTags(content.Tags)
		payload := qdrant.PointPayload{
			UserID:      job.UserID.String(),
			EntityType:  job.EntityType,
			EntityID:    job.EntityID.String(),
			SourceTable: job.SourceTable,
			Tags:        tags,
			Title:       content.Title,
			CreatedAt:   content.CreatedAt.UTC().Format(time.RFC3339),
		}
		if err := s.qdrant.Upsert(ctx, job.EntityID, vec.Slice(), payload); err != nil {
			s.failJob(&job, err)
			return
		}
	}

	s.completeJob(&job, now)
}

func (s *Service) loadContent(sourceTable string, entityID uuid.UUID) (*models.SearchableContent, error) {
	var row models.SearchableContent
	err := s.db.Where("source_table = ? AND id = ?", sourceTable, entityID).First(&row).Error
	if err != nil {
		return nil, fmt.Errorf("load searchable content: %w", err)
	}
	return &row, nil
}

func (s *Service) completeJob(job *models.EmbeddingJob, processedAt time.Time) {
	s.db.Model(job).Updates(map[string]any{
		"status":        models.EmbeddingJobDone,
		"processed_at":  processedAt,
		"last_error":    "",
	})
}

func (s *Service) failJob(job *models.EmbeddingJob, err error) {
	status := models.EmbeddingJobPending
	if job.Attempts >= s.cfg.MaxAttempts {
		status = models.EmbeddingJobFailed
	}
	s.db.Model(job).Updates(map[string]any{
		"status":     status,
		"last_error": truncateErr(err.Error(), 500),
	})
	log.Printf("embedding: job %s/%s failed (attempt %d): %v", job.SourceTable, job.EntityID, job.Attempts, err)
}

func parseTags(raw []byte) []string {
	if len(raw) == 0 {
		return nil
	}
	var tags []string
	_ = json.Unmarshal(raw, &tags)
	return tags
}

func truncateErr(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}
