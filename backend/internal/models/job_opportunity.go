package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

const (
	JobStatusOpen      = "open"
	JobStatusApplied   = "applied"
	JobStatusDismissed = "dismissed"
)

type JobOpportunity struct {
	ID          uuid.UUID      `gorm:"type:uuid;primaryKey" json:"id"`
	UserID      uuid.UUID      `gorm:"type:uuid;index;not null" json:"user_id"`
	Source      string         `gorm:"size:50;not null" json:"source"`
	ExternalID  string         `gorm:"size:200;not null" json:"external_id"`
	Title       string         `gorm:"not null" json:"title"`
	Company     string         `json:"company,omitempty"`
	Location    string         `json:"location,omitempty"`
	URL         string         `gorm:"not null" json:"url"`
	Description string         `json:"description,omitempty"`
	Skills      datatypes.JSON `gorm:"type:jsonb" json:"skills,omitempty"`
	MatchScore  float32        `json:"match_score"`
	MatchReason string         `json:"match_reason,omitempty"`
	PostedAt    *time.Time     `json:"posted_at,omitempty"`
	ScrapedAt   time.Time      `json:"scraped_at"`
	Status      string         `gorm:"size:20;default:open" json:"status"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
}

func (JobOpportunity) TableName() string { return "job_opportunities" }
