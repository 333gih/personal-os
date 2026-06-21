package models

import (
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/pgvector/pgvector-go"
	"gorm.io/datatypes"
)

type User struct {
	ID           uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	Email        string    `gorm:"type:varchar(255);uniqueIndex;not null" json:"email"`
	PasswordHash string    `gorm:"type:varchar(255);not null" json:"-"`
	Name         string    `gorm:"type:varchar(255);default:''" json:"name"`
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
	ID          uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID      uuid.UUID      `gorm:"type:uuid;index;not null" json:"user_id"`
	EntityID    uuid.UUID      `gorm:"type:uuid;index;not null" json:"entity_id"`
	Title       string         `gorm:"not null" json:"title"`
	DueAt       time.Time      `gorm:"index;not null" json:"due_at"`
	Status      string         `gorm:"default:'pending'" json:"status"`
	Kind        string         `gorm:"default:'general'" json:"kind"`
	NotifiedAt  *time.Time     `json:"notified_at,omitempty"`
	Metadata    datatypes.JSON `gorm:"type:jsonb;default:'{}'" json:"metadata,omitempty"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	CompletedAt *time.Time     `json:"completed_at,omitempty"`
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

type ReadingProgress struct {
	ID                 uuid.UUID         `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID             uuid.UUID         `gorm:"type:uuid;index;not null" json:"user_id"`
	StoryID            string            `gorm:"type:varchar(128);not null" json:"story_id"`
	StoryTitle         string            `gorm:"type:varchar(500);not null" json:"story_title"`
	ChapterID          string            `gorm:"type:varchar(128)" json:"chapter_id,omitempty"`
	ChapterTitle       string            `gorm:"type:varchar(500)" json:"chapter_title,omitempty"`
	CurrentURL         string            `gorm:"type:text" json:"current_url"`
	ProgressPercentage int               `gorm:"not null;default:0" json:"progress_percentage"`
	ScrollY            int               `gorm:"not null;default:0" json:"scroll_y"`
	ReadingTimeSeconds int               `gorm:"not null;default:0" json:"reading_time_seconds"`
	SiteID             string            `gorm:"type:varchar(64);not null;default:'generic'" json:"site_id"`
	Metadata           datatypes.JSONMap `gorm:"type:jsonb;default:'{}'" json:"metadata"`
	ClientTimestamp    *time.Time        `json:"client_timestamp,omitempty"`
	LastReadAt         time.Time         `gorm:"index;not null" json:"last_read_at"`
	CreatedAt          time.Time         `json:"created_at"`
	UpdatedAt          time.Time         `json:"updated_at"`
}

func (ReadingProgress) TableName() string {
	return "reading_progress"
}

// Entity type constants
const (
	DomainInbox         = "inbox"
	DomainLearning      = "learning"
	DomainWork          = "work"
	DomainStartup       = "startup"
	DomainGoal          = "goal"
	DomainJournal       = "journal"
	DomainEntertainment = "entertainment"

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
	TypeWorkInterviewTopic = "work_interview_topic"
	TypeWorkEmployer    = "work_employer"
	TypeWorkRole        = "work_role"
	TypeWorkProject     = "work_project"
	TypeWorkFeature     = "work_feature"
	TypeWorkDesignDoc   = "work_design_doc"
	TypeWorkCVEntry     = "work_cv_entry"
	TypeWorkCVDocument  = "work_cv_document"
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
	TypeGoalTarget      = "goal_target"
	TypeGoalHabit       = "goal_habit"
	TypeGoalMilestone   = "goal_milestone"
	TypeJournalEntry    = "journal_entry"
	TypeJournalReflection = "journal_reflection"
	TypeJournalDailyLog = "journal_daily_log"
)

func DomainForType(entityType string) string {
	switch entityType {
	case TypeInboxText, TypeInboxURL, TypeInboxFile, TypeInboxVoice, TypeInboxNote:
		return DomainInbox
	case TypeCourse, TypeCertificate, TypeSkill, TypeTopic, TypeLearningNote:
		return DomainLearning
	case TypeWorkEmployer, TypeWorkRole, TypeWorkProject, TypeWorkFeature, TypeWorkDesignDoc, TypeWorkCVEntry, TypeWorkCVDocument,
		TypeTechnology, TypeProblem, TypeDecision, TypeLesson, TypeWorkInterviewTopic:
		return DomainWork
	case TypeGoalTarget, TypeGoalHabit, TypeGoalMilestone:
		return DomainGoal
	case TypeJournalEntry, TypeJournalReflection, TypeJournalDailyLog:
		return DomainJournal
	default:
		if strings.HasPrefix(entityType, "goal_") {
			return DomainGoal
		}
		if strings.HasPrefix(entityType, "journal_") {
			return DomainJournal
		}
		return DomainStartup
	}
}

type LearningSchedule struct {
	UserID               uuid.UUID      `gorm:"type:uuid;primaryKey" json:"user_id"`
	WorkStartHour        int            `gorm:"not null;default:8" json:"work_start_hour"`
	WorkEndHour          int            `gorm:"not null;default:17" json:"work_end_hour"`
	WorkDays             datatypes.JSON `gorm:"type:jsonb;not null;default:'[1,2,3,4,5]'" json:"work_days"`
	CommuteMinutes       int            `gorm:"not null;default:40" json:"commute_minutes"`
	MorningCommuteTime   string         `gorm:"type:time;not null;default:'07:15'" json:"morning_commute_time"`
	EveningCommuteTime   string         `gorm:"type:time;not null;default:'17:30'" json:"evening_commute_time"`
	ToeicSessionTime     string         `gorm:"type:time;not null;default:'20:00'" json:"toeic_session_time"`
	DsaCommuteMinutes    int            `gorm:"not null;default:25" json:"dsa_commute_minutes"`
	EnglishCommuteMinutes int           `gorm:"not null;default:20" json:"english_commute_minutes"`
	ToeicDailyMinutes    int            `gorm:"not null;default:60" json:"toeic_daily_minutes"`
	Timezone             string         `gorm:"not null;default:'Asia/Ho_Chi_Minh'" json:"timezone"`
	PushEnabled          bool           `gorm:"not null;default:true" json:"push_enabled"`
	CreatedAt            time.Time      `json:"created_at"`
	UpdatedAt            time.Time      `json:"updated_at"`
}

func (LearningSchedule) TableName() string { return "learning_schedules" }

type StudyJob struct {
	ID           uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID       uuid.UUID      `gorm:"type:uuid;index;not null" json:"user_id"`
	Kind         string         `gorm:"not null" json:"kind"`
	Status       string         `gorm:"not null;default:'pending'" json:"status"`
	Input        datatypes.JSON `gorm:"type:jsonb;not null;default:'{}'" json:"input"`
	Result       datatypes.JSON `gorm:"type:jsonb" json:"result,omitempty"`
	ErrorMessage string         `json:"error_message,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
}

func (StudyJob) TableName() string { return "study_jobs" }

type NotificationLog struct {
	ID             uuid.UUID         `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID         uuid.UUID         `gorm:"type:uuid;index;not null" json:"user_id"`
	Channel        string            `gorm:"not null;default:'push'" json:"channel"`
	Title          string            `gorm:"not null" json:"title"`
	Body           string            `gorm:"not null" json:"body"`
	Status         string            `gorm:"not null;default:'queued'" json:"status"`
	Payload        datatypes.JSONMap `gorm:"type:jsonb;not null;default:'{}'" json:"payload"`
	IdempotencyKey string            `json:"idempotency_key,omitempty"`
	ErrorMessage   string            `json:"error_message,omitempty"`
	CreatedAt      time.Time         `json:"created_at"`
}

func (NotificationLog) TableName() string { return "notification_logs" }
