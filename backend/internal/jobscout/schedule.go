package jobscout

import (
	"context"
	"fmt"
	"log"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/notification"
)

const (
	defaultDailyScanHour = 7
	dailyScanLocation    = "Asia/Ho_Chi_Minh"
)

type ScheduleWorker struct {
	svc      *Service
	interval time.Duration
	scanHour int

	mu              sync.Mutex
	lastDailyRunKey string
}

func NewScheduleWorker(svc *Service, interval time.Duration) *ScheduleWorker {
	if interval <= 0 {
		interval = 15 * time.Minute
	}
	return &ScheduleWorker{
		svc:      svc,
		interval: interval,
		scanHour: defaultDailyScanHour,
	}
}

func (w *ScheduleWorker) Start(ctx context.Context) {
	log.Printf("jobscout: schedule worker started (tick=%s, daily=%02d:00 %s)",
		w.interval, w.scanHour, dailyScanLocation)
	ticker := time.NewTicker(w.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			w.maybeRunDaily(ctx)
		}
	}
}

func (w *ScheduleWorker) maybeRunDaily(ctx context.Context) {
	loc, err := time.LoadLocation(dailyScanLocation)
	if err != nil {
		loc = time.UTC
	}
	now := time.Now().In(loc)
	if now.Hour() != w.scanHour {
		return
	}
	runKey := now.Format("2006-01-02")

	w.mu.Lock()
	if w.lastDailyRunKey == runKey {
		w.mu.Unlock()
		return
	}
	w.lastDailyRunKey = runKey
	w.mu.Unlock()

	log.Printf("jobscout: daily scan starting (%s)", runKey)
	w.svc.runDailyScans(ctx, runKey)
}

func (s *Service) runDailyScans(ctx context.Context, runKey string) {
	var userIDs []uuid.UUID
	if err := s.db.Model(&models.User{}).Pluck("id", &userIDs).Error; err != nil {
		log.Printf("jobscout: daily scan list users: %v", err)
		return
	}
	for _, userID := range userIDs {
		if !s.moduleEnabled(userID) {
			continue
		}
		if !s.dailyScanEnabled(userID) {
			continue
		}
		result, err := s.Scan(userID)
		if err != nil {
			log.Printf("jobscout: daily scan user %s: %v", userID, err)
			continue
		}
		s.touchLastScan(userID)
		s.notifyNewJobs(ctx, userID, result, runKey)
	}
}

func (s *Service) dailyScanEnabled(userID uuid.UUID) bool {
	var row models.JobSearchPreferences
	if err := s.db.Where("user_id = ?", userID).First(&row).Error; err != nil {
		return true
	}
	return row.DailyScanEnabled
}

func (s *Service) pushEnabled(userID uuid.UUID) bool {
	var row models.JobSearchPreferences
	if err := s.db.Where("user_id = ?", userID).First(&row).Error; err != nil {
		return true
	}
	return row.PushEnabled
}

func (s *Service) touchLastScan(userID uuid.UUID) {
	now := time.Now().UTC()
	_ = s.db.Model(&models.JobSearchPreferences{}).
		Where("user_id = ?", userID).
		Update("last_scan_at", now).Error
}

func (s *Service) notifyNewJobs(ctx context.Context, userID uuid.UUID, result *ScanResult, runKey string) {
	if s.notify == nil || result == nil || result.Stored == 0 {
		return
	}
	if !s.pushEnabled(userID) {
		return
	}

	topJobs, _ := s.latestStoredJobs(userID, 3)
	body := fmt.Sprintf("%d new job%s match your CV and focus skills.",
		result.Stored, plural(result.Stored))
	if len(topJobs) > 0 {
		body += " " + formatJobTitles(topJobs)
	}

	_, _ = s.notify.Send(ctx, notification.SendInput{
		UserID: userID,
		Title:  "New jobs for you",
		Body:   body,
		Type:   "personalos.jobs.new_matches",
		DeepLink: "/jobs",
		IdempotencyKey: fmt.Sprintf("jobscout:daily:%s:%s", runKey, userID),
		Priority:       "normal",
	})
}

func (s *Service) latestStoredJobs(userID uuid.UUID, limit int) ([]models.JobOpportunity, error) {
	if limit <= 0 {
		limit = 3
	}
	var rows []models.JobOpportunity
	err := s.db.Where("user_id = ? AND status = ?", userID, models.JobStatusOpen).
		Order("scraped_at DESC, match_score DESC").
		Limit(limit).
		Find(&rows).Error
	return rows, err
}

func formatJobTitles(jobs []models.JobOpportunity) string {
	parts := make([]string, 0, len(jobs))
	for _, j := range jobs {
		title := strings.TrimSpace(j.Title)
		if title == "" {
			continue
		}
		if c := strings.TrimSpace(j.Company); c != "" {
			title = title + " @ " + c
		}
		parts = append(parts, title)
	}
	if len(parts) == 0 {
		return ""
	}
	if len(parts) == 1 {
		return parts[0] + "."
	}
	return strings.Join(parts, "; ") + "."
}

func plural(n int) string {
	if n == 1 {
		return ""
	}
	return "s"
}
