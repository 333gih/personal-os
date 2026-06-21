package notification

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

// RequestedEvent matches fash-notification-service Kafka contract (topic notifications.requested).
type RequestedEvent struct {
	EventID          string            `json:"event_id"`
	RecipientUserIDs []string          `json:"recipient_user_ids"`
	Title            string            `json:"title"`
	Body             string            `json:"body"`
	Data             map[string]string `json:"data,omitempty"`
	Locale           string            `json:"locale,omitempty"`
	Priority         string            `json:"priority,omitempty"`
	CreatedAt        time.Time         `json:"created_at"`
	IdempotencyKey   string            `json:"idempotency_key,omitempty"`
}

func NewRequestedEvent(recipientUserIDs []string, title, body, locale, priority string, data map[string]string, idempotencyKey string) RequestedEvent {
	if priority == "" {
		priority = "normal"
	}
	if locale == "" {
		locale = "en"
	}
	return RequestedEvent{
		EventID:          uuid.New().String(),
		RecipientUserIDs: recipientUserIDs,
		Title:            title,
		Body:             body,
		Data:             data,
		Locale:           locale,
		Priority:         priority,
		CreatedAt:        time.Now().UTC(),
		IdempotencyKey:   idempotencyKey,
	}
}

func (e RequestedEvent) JSON() ([]byte, error) {
	return json.Marshal(e)
}
