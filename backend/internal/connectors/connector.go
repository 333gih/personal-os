package connectors

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
)

// CalendarSyncer pushes Personal OS reminders to external calendars.
type CalendarSyncer interface {
	SyncStudyReminder(ctx context.Context, userID uuid.UUID, rem models.Reminder, durationMin int) error
	Connected(ctx context.Context, userID uuid.UUID) bool
}

// IntegrationStatus describes a third-party connector for a user.
type IntegrationStatus struct {
	Provider  string     `json:"provider"`
	Label     string     `json:"label"`
	Connected bool       `json:"connected"`
	Scopes    string     `json:"scopes,omitempty"`
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
}
