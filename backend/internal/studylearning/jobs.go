package studylearning

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/learningimport"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/notification"
	"gorm.io/datatypes"
)

type JobDTO struct {
	ID           string         `json:"id"`
	Kind         string         `json:"kind"`
	Status       string         `json:"status"`
	Result       map[string]any `json:"result,omitempty"`
	ErrorMessage string         `json:"error_message,omitempty"`
	CreatedAt    time.Time      `json:"created_at"`
	UpdatedAt    time.Time      `json:"updated_at"`
}

type CoachAsyncInput struct {
	EntityID string
	Topic    string
	Track    string
	Focus    string
}

func (s *Service) EnqueueCoach(userID uuid.UUID, in CoachAsyncInput) (*JobDTO, error) {
	inRaw, _ := json.Marshal(in)
	job := models.StudyJob{
		UserID: userID,
		Kind:   "learning_coach",
		Status: "pending",
		Input:  datatypes.JSON(inRaw),
	}
	if err := s.db.Create(&job).Error; err != nil {
		return nil, err
	}
	return jobToDTO(&job), nil
}

func (s *Service) GetJob(userID, jobID uuid.UUID) (*JobDTO, error) {
	var job models.StudyJob
	if err := s.db.Where("id = ? AND user_id = ?", jobID, userID).First(&job).Error; err != nil {
		return nil, err
	}
	return jobToDTO(&job), nil
}

func (s *Service) ProcessPendingJobs(ctx context.Context, limit int) error {
	if limit <= 0 {
		limit = 3
	}
	var jobs []models.StudyJob
	if err := s.db.Where("status = 'pending'").Order("created_at ASC").Limit(limit).Find(&jobs).Error; err != nil {
		return err
	}
	for _, job := range jobs {
		if err := s.runJob(ctx, &job); err != nil {
			continue
		}
	}
	return nil
}

func (s *Service) runJob(ctx context.Context, job *models.StudyJob) error {
	now := time.Now()
	res := s.db.Model(job).Where("id = ? AND status = 'pending'", job.ID).
		Updates(map[string]any{"status": "running", "updated_at": now})
	if res.RowsAffected == 0 {
		return nil
	}

	var in CoachAsyncInput
	_ = json.Unmarshal(job.Input, &in)

	result, err := s.learning.Coach(job.UserID, learningimport.CoachInput{
		EntityID: in.EntityID,
		Topic:    in.Topic,
		Track:    in.Track,
		Focus:    in.Focus,
	})

	if err != nil {
		msg := err.Error()
		_ = s.db.Model(job).Updates(map[string]any{
			"status": "failed", "error_message": msg, "updated_at": time.Now(),
		}).Error
		if s.notify != nil {
			_, _ = s.notify.Send(ctx, notification.SendInput{
				UserID:         job.UserID,
				Title:          "AI coach failed",
				Body:           msg,
				Type:           "personalos.learning.job_failed",
				IdempotencyKey: fmt.Sprintf("job-fail:%s", job.ID),
				Priority:       "high",
			})
		}
		return err
	}

	raw, _ := json.Marshal(result)
	_ = s.db.Model(job).Updates(map[string]any{
		"status": "done", "result": datatypes.JSON(raw), "updated_at": time.Now(),
	}).Error

	if s.notify != nil {
		topic := in.Topic
		if topic == "" {
			topic = "your study topic"
		}
		_, _ = s.notify.Send(ctx, notification.SendInput{
			UserID: job.UserID,
			Title:  "AI coach ready",
			Body:   fmt.Sprintf("Practice plan ready for %s — open Learning to review.", topic),
			Type:   "personalos.learning.coach_done",
			DeepLink: "/learning",
			IdempotencyKey: fmt.Sprintf("job-done:%s", job.ID),
			Priority:       "high",
		})
	}
	return nil
}

func jobToDTO(j *models.StudyJob) *JobDTO {
	dto := &JobDTO{
		ID:           j.ID.String(),
		Kind:         j.Kind,
		Status:       j.Status,
		ErrorMessage: j.ErrorMessage,
		CreatedAt:    j.CreatedAt,
		UpdatedAt:    j.UpdatedAt,
	}
	if len(j.Result) > 0 {
		_ = json.Unmarshal(j.Result, &dto.Result)
	}
	return dto
}

func (s *Service) DispatchDueReminders(ctx context.Context) error {
	now := time.Now().UTC()
	var reminders []models.Reminder
	err := s.db.Where("status = 'pending' AND notified_at IS NULL AND due_at <= ? AND kind IN ?",
		now, []string{kindStudySchedule, kindLearningJob}).
		Order("due_at ASC").Limit(50).Find(&reminders).Error
	if err != nil {
		return err
	}

	for _, rem := range reminders {
		if s.notify == nil {
			continue
		}
		var sched models.LearningSchedule
		if err := s.db.Where("user_id = ?", rem.UserID).First(&sched).Error; err == nil && !sched.PushEnabled {
			t := now
			_ = s.db.Model(&rem).Update("notified_at", t).Error
			continue
		}

		body := "Time for your study block — optimized for commute."
		typ := "personalos.learning.reminder"
		if rem.Kind == kindStudySchedule {
			var meta map[string]string
			_ = json.Unmarshal(rem.Metadata, &meta)
			switch meta["mode"] {
			case "flash":
				body = "Metro/bus DSA flash: recall one pattern before checking notes."
			case "vocab":
				body = "TOEIC vocab sprint — 10 collocations, no distractions."
			case "deep":
				body = "TOEIC deep block: grammar + listening/reading rotation."
			}
		}

		idem := fmt.Sprintf("reminder:%s", rem.ID)
		_, err := s.notify.Send(ctx, notification.SendInput{
			UserID:         rem.UserID,
			Title:          rem.Title,
			Body:           body,
			Type:           typ,
			DeepLink:       "/learning",
			IdempotencyKey: idem,
		})
		if err != nil {
			continue
		}
		t := time.Now().UTC()
		_ = s.db.Model(&rem).Update("notified_at", t).Error
	}
	return nil
}

func (s *Service) EnsureAllUsersTodayReminders() error {
	var userIDs []uuid.UUID
	if err := s.db.Model(&models.LearningSchedule{}).Pluck("user_id", &userIDs).Error; err != nil {
		return err
	}
	for _, id := range userIDs {
		s.EnsureTodayReminders(id)
	}
	return nil
}
