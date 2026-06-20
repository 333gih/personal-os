package models

import (
	"time"

	"github.com/google/uuid"
)

const (
	SourceTableEntities        = "entities"
	SourceTableReadingProgress = "reading_progress"

	EmbeddingJobPending    = "pending"
	EmbeddingJobProcessing = "processing"
	EmbeddingJobDone       = "done"
	EmbeddingJobFailed     = "failed"

	AITypeTask      = "TASK"
	AITypeWork      = "WORK"
	AITypeLearning  = "LEARNING"
	AITypeStartup   = "STARTUP"
	AITypeBook      = "BOOK"
	AITypeGoal      = "GOAL"
	AITypeJournal   = "JOURNAL"
)

type EmbeddingJob struct {
	ID          uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	UserID      uuid.UUID  `gorm:"type:uuid;index;not null"`
	SourceTable string     `gorm:"type:varchar(50);not null"`
	EntityType  string     `gorm:"type:varchar(50);not null"`
	EntityID    uuid.UUID  `gorm:"type:uuid;not null"`
	Status      string     `gorm:"type:varchar(20);default:'pending'"`
	Attempts    int        `gorm:"default:0"`
	LastError   string     `gorm:"type:text"`
	CreatedAt   time.Time  `gorm:"autoCreateTime"`
	ProcessedAt *time.Time
}

func (EmbeddingJob) TableName() string { return "ai.embedding_jobs" }

type AIInteraction struct {
	ID        uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()"`
	UserID    uuid.UUID `gorm:"type:uuid;index;not null"`
	Endpoint  string    `gorm:"type:varchar(50);not null"`
	Model     string    `gorm:"type:varchar(100)"`
	TokensIn  int       `gorm:"default:0"`
	TokensOut int       `gorm:"default:0"`
	LatencyMs int       `gorm:"default:0"`
	CreatedAt time.Time `gorm:"autoCreateTime"`
}

func (AIInteraction) TableName() string { return "ai.ai_interactions" }

type ModelUsage struct {
	UserID  uuid.UUID `gorm:"type:uuid;primaryKey"`
	Model   string    `gorm:"type:varchar(100);primaryKey"`
	Date    time.Time `gorm:"type:date;primaryKey"`
	Tokens  int64     `gorm:"default:0"`
	CostUSD float64   `gorm:"type:numeric(10,6);default:0"`
}

func (ModelUsage) TableName() string { return "ai.model_usage" }

type SearchableContent struct {
	ID          uuid.UUID `gorm:"type:uuid"`
	UserID      uuid.UUID `gorm:"type:uuid"`
	EntityType  string
	SourceTable string
	Title       string
	Content     string
	Tags        []byte `gorm:"type:jsonb"`
	Metadata    []byte `gorm:"type:jsonb"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

func (SearchableContent) TableName() string { return "ai.searchable_content" }
