package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/pgvector/pgvector-go"
	"gorm.io/datatypes"
)

type User struct {
	ID           uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Email        string    `gorm:"uniqueIndex;not null" json:"email"`
	PasswordHash string    `gorm:"not null" json:"-"`
	Name         string    `json:"name"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

type Entity struct {
	ID        uuid.UUID         `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    uuid.UUID         `gorm:"type:uuid;index;not null" json:"user_id"`
	Type      string            `gorm:"index;not null" json:"type"`
	Title     string            `gorm:"not null" json:"title"`
	Content   string            `gorm:"type:text" json:"content"`
	Tags      datatypes.JSON    `gorm:"type:jsonb;default:'[]'" json:"tags"`
	Source    string            `json:"source"`
	Metadata  datatypes.JSONMap `gorm:"type:jsonb;default:'{}'" json:"metadata"`
	Embedding pgvector.Vector   `gorm:"type:vector(1536)" json:"-"`
	Status    string            `gorm:"default:'active'" json:"status"`
	Domain    string            `gorm:"index" json:"domain"`
	CreatedAt time.Time         `json:"created_at"`
	UpdatedAt time.Time         `json:"updated_at"`
}

type Relationship struct {
	ID             uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID         uuid.UUID `gorm:"type:uuid;index;not null" json:"user_id"`
	SourceEntityID uuid.UUID `gorm:"type:uuid;index;not null" json:"source_entity_id"`
	TargetEntityID uuid.UUID `gorm:"type:uuid;index;not null" json:"target_entity_id"`
	RelationType   string    `gorm:"index;not null" json:"relation_type"`
	CreatedAt      time.Time `json:"created_at"`
}

type Reminder struct {
	ID        uuid.UUID  `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID    uuid.UUID  `gorm:"type:uuid;index;not null" json:"user_id"`
	EntityID  uuid.UUID  `gorm:"type:uuid;index;not null" json:"entity_id"`
	Title     string     `gorm:"not null" json:"title"`
	DueAt     time.Time  `gorm:"index;not null" json:"due_at"`
	Status    string     `gorm:"default:'pending'" json:"status"`
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	CompletedAt *time.Time `json:"completed_at,omitempty"`
}

type File struct {
	ID         uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID     uuid.UUID `gorm:"type:uuid;index;not null" json:"user_id"`
	EntityID   *uuid.UUID `gorm:"type:uuid;index" json:"entity_id,omitempty"`
	Filename   string    `gorm:"not null" json:"filename"`
	MimeType   string    `json:"mime_type"`
	Size       int64     `json:"size"`
	StorageKey string    `gorm:"not null" json:"storage_key"`
	CreatedAt  time.Time `json:"created_at"`
}

// Entity type constants
const (
	DomainInbox    = "inbox"
	DomainLearning = "learning"
	DomainWork     = "work"
	DomainStartup  = "startup"

	TypeInboxText       = "inbox_text"
	TypeInboxURL        = "inbox_url"
	TypeInboxFile       = "inbox_file"
	TypeInboxVoice      = "inbox_voice"
	TypeInboxNote       = "inbox_note"
	TypeCourse          = "learning_course"
	TypeCertificate     = "learning_certificate"
	TypeSkill           = "learning_skill"
	TypeTopic           = "learning_topic"
	TypeLearningNote    = "learning_note"
	TypeWorkProject     = "work_project"
	TypeWorkFeature     = "work_feature"
	TypeTechnology      = "work_technology"
	TypeProblem         = "work_problem"
	TypeDecision        = "work_decision"
	TypeLesson          = "work_lesson"
	TypeStartupIdea     = "startup_idea"
	TypePainPoint       = "startup_pain_point"
	TypeBusinessModel   = "startup_business_model"
	TypeStartupFeature  = "startup_feature"
	TypeKPI             = "startup_kpi"
	TypeCompetitor      = "startup_competitor"
)

func DomainForType(entityType string) string {
	switch entityType {
	case TypeInboxText, TypeInboxURL, TypeInboxFile, TypeInboxVoice, TypeInboxNote:
		return DomainInbox
	case TypeCourse, TypeCertificate, TypeSkill, TypeTopic, TypeLearningNote:
		return DomainLearning
	case TypeWorkProject, TypeWorkFeature, TypeTechnology, TypeProblem, TypeDecision, TypeLesson:
		return DomainWork
	default:
		return DomainStartup
	}
}
