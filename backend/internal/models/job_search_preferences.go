package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/datatypes"
)

const (
	WorkLocationRemote  = "remote"
	WorkLocationHybrid  = "hybrid"
	WorkLocationOnsite  = "onsite"
	WorkLocationAnywhere = "anywhere"

	EmploymentFullTime   = "full_time"
	EmploymentContract   = "contract"
	EmploymentPartTime   = "part_time"
	EmploymentInternship = "internship"
	EmploymentTemporary  = "temporary"
)

type JobSearchPreferences struct {
	UserID            uuid.UUID      `gorm:"type:uuid;primaryKey" json:"user_id"`
	FocusSkills       datatypes.JSON `gorm:"type:jsonb;not null;default:'[]'" json:"focus_skills"`
	YearsExperience   float32        `gorm:"not null;default:3" json:"years_experience"`
	TargetRole        string         `gorm:"not null;default:''" json:"target_role"`
	WorkLocationTypes datatypes.JSON `gorm:"type:jsonb;not null;default:'[\"remote\"]'" json:"work_location_types"`
	EmploymentTypes   datatypes.JSON `gorm:"type:jsonb;not null;default:'[\"full_time\"]'" json:"employment_types"`
	UpdatedAt         time.Time      `json:"updated_at"`
}

func (JobSearchPreferences) TableName() string { return "job_search_preferences" }
