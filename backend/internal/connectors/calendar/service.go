package calendar

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"gorm.io/gorm"
)

const (
	ProviderGoogle = "google"
	calendarScope  = "https://www.googleapis.com/auth/calendar.events"
)

type Config struct {
	ClientID     string
	ClientSecret string
	RedirectURL  string
}

type Service struct {
	db    *gorm.DB
	cfg   Config
	oauth *oauth2.Config
}

func NewService(db *gorm.DB, cfg Config) *Service {
	oauthCfg := &oauth2.Config{
		ClientID:     cfg.ClientID,
		ClientSecret: cfg.ClientSecret,
		RedirectURL:  cfg.RedirectURL,
		Scopes:       []string{calendarScope},
		Endpoint:     google.Endpoint,
	}
	return &Service{db: db, cfg: cfg, oauth: oauthCfg}
}

func (s *Service) Configured() bool {
	return strings.TrimSpace(s.cfg.ClientID) != "" &&
		strings.TrimSpace(s.cfg.ClientSecret) != "" &&
		strings.TrimSpace(s.cfg.RedirectURL) != ""
}

func (s *Service) AuthURL(state string) (string, error) {
	if !s.Configured() {
		return "", errors.New("google calendar OAuth not configured")
	}
	return s.oauth.AuthCodeURL(state, oauth2.AccessTypeOffline, oauth2.ApprovalForce), nil
}

func (s *Service) Exchange(ctx context.Context, userID uuid.UUID, code string) error {
	if !s.Configured() {
		return errors.New("google calendar OAuth not configured")
	}
	tok, err := s.oauth.Exchange(ctx, code)
	if err != nil {
		return err
	}
	return s.saveToken(userID, tok)
}

func (s *Service) Connected(ctx context.Context, userID uuid.UUID) bool {
	_, err := s.token(ctx, userID)
	return err == nil
}

func (s *Service) Status(_ context.Context, userID uuid.UUID) models.UserIntegrationToken {
	var row models.UserIntegrationToken
	if err := s.db.Where("user_id = ? AND provider = ?", userID, ProviderGoogle).First(&row).Error; err != nil {
		return models.UserIntegrationToken{Provider: ProviderGoogle}
	}
	return row
}

func (s *Service) Disconnect(userID uuid.UUID) error {
	return s.db.Where("user_id = ? AND provider = ?", userID, ProviderGoogle).
		Delete(&models.UserIntegrationToken{}).Error
}

func (s *Service) SyncStudyReminder(ctx context.Context, userID uuid.UUID, rem models.Reminder, durationMin int) error {
	if durationMin <= 0 {
		durationMin = 45
	}
	tok, err := s.token(ctx, userID)
	if err != nil {
		return err
	}

	calendarID := "primary"
	var pref models.UserModulePref
	if err := s.db.Where("user_id = ? AND module_id = ?", userID, models.ModuleLearning).First(&pref).Error; err == nil {
		if v, ok := pref.Config["calendar_id"].(string); ok && v != "" {
			calendarID = v
		}
	}

	start := rem.DueAt.UTC()
	end := start.Add(time.Duration(durationMin) * time.Minute)
	body := map[string]any{
		"summary":     rem.Title,
		"description": "Personal OS study block",
		"start":       map[string]string{"dateTime": start.Format(time.RFC3339), "timeZone": "UTC"},
		"end":         map[string]string{"dateTime": end.Format(time.RFC3339), "timeZone": "UTC"},
	}

	var existing models.CalendarSyncEvent
	err = s.db.Where("user_id = ? AND source_kind = ? AND source_id = ? AND provider = ?",
		userID, rem.Kind, rem.ID, ProviderGoogle).First(&existing).Error

	httpClient := s.oauth.Client(ctx, tok)
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return s.insertEvent(ctx, httpClient, calendarID, body, userID, rem)
	}
	if err != nil {
		return err
	}
	return s.patchEvent(ctx, httpClient, calendarID, existing, body)
}

func (s *Service) insertEvent(ctx context.Context, client *http.Client, calendarID string, body map[string]any, userID uuid.UUID, rem models.Reminder) error {
	raw, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost,
		fmt.Sprintf("https://www.googleapis.com/calendar/v3/calendars/%s/events", url.PathEscape(calendarID)),
		bytes.NewReader(raw))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("calendar insert: %s", string(b))
	}
	var created struct {
		ID string `json:"id"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&created); err != nil {
		return err
	}
	row := models.CalendarSyncEvent{
		UserID: userID, SourceKind: rem.Kind, SourceID: rem.ID,
		Provider: ProviderGoogle, ExternalEventID: created.ID,
	}
	return s.db.Create(&row).Error
}

func (s *Service) patchEvent(ctx context.Context, client *http.Client, calendarID string, existing models.CalendarSyncEvent, body map[string]any) error {
	raw, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPatch,
		fmt.Sprintf("https://www.googleapis.com/calendar/v3/calendars/%s/events/%s",
			url.PathEscape(calendarID), url.PathEscape(existing.ExternalEventID)),
		bytes.NewReader(raw))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode >= 300 {
		b, _ := io.ReadAll(resp.Body)
		return fmt.Errorf("calendar update: %s", string(b))
	}
	return s.db.Model(&existing).Update("updated_at", time.Now().UTC()).Error
}

func (s *Service) token(ctx context.Context, userID uuid.UUID) (*oauth2.Token, error) {
	var row models.UserIntegrationToken
	if err := s.db.Where("user_id = ? AND provider = ?", userID, ProviderGoogle).First(&row).Error; err != nil {
		return nil, err
	}
	tok := &oauth2.Token{
		AccessToken:  row.AccessToken,
		RefreshToken: row.RefreshToken,
		TokenType:    row.TokenType,
	}
	if row.ExpiresAt != nil {
		tok.Expiry = row.ExpiresAt.UTC()
	}
	if tok.Valid() {
		return tok, nil
	}
	if tok.RefreshToken == "" {
		return nil, errors.New("calendar token expired")
	}
	refreshed, err := s.oauth.TokenSource(ctx, tok).Token()
	if err != nil {
		return nil, err
	}
	if refreshed.AccessToken != row.AccessToken {
		_ = s.saveToken(userID, refreshed)
	}
	return refreshed, nil
}

func (s *Service) saveToken(userID uuid.UUID, tok *oauth2.Token) error {
	var expires *time.Time
	if !tok.Expiry.IsZero() {
		t := tok.Expiry.UTC()
		expires = &t
	}
	var row models.UserIntegrationToken
	err := s.db.Where("user_id = ? AND provider = ?", userID, ProviderGoogle).First(&row).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		row = models.UserIntegrationToken{
			UserID: userID, Provider: ProviderGoogle,
			AccessToken: tok.AccessToken, RefreshToken: tok.RefreshToken,
			TokenType: tok.TokenType, ExpiresAt: expires, Scopes: calendarScope,
			Metadata: map[string]any{},
		}
		return s.db.Create(&row).Error
	}
	if err != nil {
		return err
	}
	row.AccessToken = tok.AccessToken
	if tok.RefreshToken != "" {
		row.RefreshToken = tok.RefreshToken
	}
	row.TokenType = tok.TokenType
	row.ExpiresAt = expires
	row.Scopes = calendarScope
	row.UpdatedAt = time.Now().UTC()
	return s.db.Save(&row).Error
}
