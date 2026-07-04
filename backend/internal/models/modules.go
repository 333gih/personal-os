package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

const (
	ModuleCore          = "core"
	ModuleInbox         = "inbox"
	ModuleSearch        = "search"
	ModuleWork          = "work"
	ModuleLearning      = "learning"
	ModuleStartup       = "startup"
	ModuleEntertainment = "entertainment"
	ModuleGoals         = "goals"
	ModuleJournal       = "journal"
)

type UserModulePref struct {
	UserID    uuid.UUID         `gorm:"type:uuid;primaryKey" json:"user_id"`
	ModuleID  string            `gorm:"type:varchar(32);primaryKey" json:"module_id"`
	Enabled   bool              `gorm:"not null;default:true" json:"enabled"`
	PinOrder  *int              `json:"pin_order,omitempty"`
	Config    datatypes.JSONMap `gorm:"type:jsonb;not null;default:'{}'" json:"config"`
	UpdatedAt time.Time         `json:"updated_at"`
}

func (UserModulePref) TableName() string { return "user_module_prefs" }

type UserIntegrationToken struct {
	ID           uuid.UUID         `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID       uuid.UUID         `gorm:"type:uuid;index;not null" json:"user_id"`
	Provider     string            `gorm:"type:varchar(32);not null" json:"provider"`
	AccessToken  string            `gorm:"type:text;not null" json:"-"`
	RefreshToken string            `gorm:"type:text" json:"-"`
	TokenType    string            `gorm:"type:varchar(32);default:'Bearer'" json:"token_type"`
	ExpiresAt    *time.Time        `json:"expires_at,omitempty"`
	Scopes       string            `gorm:"type:text" json:"scopes,omitempty"`
	Metadata     datatypes.JSONMap `gorm:"type:jsonb;not null;default:'{}'" json:"metadata"`
	CreatedAt    time.Time         `json:"created_at"`
	UpdatedAt    time.Time         `json:"updated_at"`
}

func (UserIntegrationToken) TableName() string { return "user_integration_tokens" }

type CalendarSyncEvent struct {
	ID              uuid.UUID `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	UserID          uuid.UUID `gorm:"type:uuid;index;not null" json:"user_id"`
	SourceKind      string    `gorm:"type:varchar(64);not null" json:"source_kind"`
	SourceID        uuid.UUID `gorm:"type:uuid;not null" json:"source_id"`
	Provider        string    `gorm:"type:varchar(32);not null;default:'google'" json:"provider"`
	ExternalEventID string    `gorm:"type:varchar(256);not null" json:"external_event_id"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

func (CalendarSyncEvent) TableName() string { return "calendar_sync_events" }
