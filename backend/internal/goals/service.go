package goals

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

const reflectPrompt = `You are a personal goal coach. Given the user's active goals and habits, write a weekly reflection.
Respond with JSON only:
{"summary":"2-3 sentence overview","wins":["win1","win2"],"blockers":["blocker1"],"focus_next_week":["action1","action2"],"encouragement":"one warm sentence"}`

type Service struct {
	db *gorm.DB
	ai *ai.Service
}

func NewService(db *gorm.DB, aiSvc *ai.Service) *Service {
	return &Service{db: db, ai: aiSvc}
}

type HabitSummary struct {
	ID    string `json:"id"`
	Title string `json:"title"`
}

type TargetSummary struct {
	ID    string `json:"id"`
	Title string `json:"title"`
}

type Summary struct {
	ActiveHabits    int            `json:"active_habits"`
	ActiveTargets   int            `json:"active_targets"`
	ActiveMilestones int           `json:"active_milestones"`
	Habits          []HabitSummary `json:"habits"`
	Targets         []TargetSummary `json:"targets"`
}

func (s *Service) Summary(userID uuid.UUID) (*Summary, error) {
	var entities []models.Entity
	if err := s.db.Where("user_id = ? AND domain = ? AND status = 'active'", userID, models.DomainGoal).
		Order("updated_at DESC").Find(&entities).Error; err != nil {
		return nil, err
	}

	out := &Summary{}
	for _, e := range entities {
		switch e.Type {
		case models.TypeGoalHabit:
			out.ActiveHabits++
			out.Habits = append(out.Habits, HabitSummary{ID: e.ID.String(), Title: e.Title})
		case models.TypeGoalTarget:
			out.ActiveTargets++
			out.Targets = append(out.Targets, TargetSummary{ID: e.ID.String(), Title: e.Title})
		case models.TypeGoalMilestone:
			out.ActiveMilestones++
		}
	}
	return out, nil
}

type ReflectInput struct {
	Notes string `json:"notes"`
}

type ReflectResult struct {
	Summary          string   `json:"summary"`
	Wins             []string `json:"wins"`
	Blockers         []string `json:"blockers"`
	FocusNextWeek    []string `json:"focus_next_week"`
	Encouragement    string   `json:"encouragement"`
	GeneratedAt      time.Time `json:"generated_at"`
}

type reflectPayload struct {
	Summary       string   `json:"summary"`
	Wins          []string `json:"wins"`
	Blockers      []string `json:"blockers"`
	FocusNextWeek []string `json:"focus_next_week"`
	Encouragement string   `json:"encouragement"`
}

func (s *Service) Reflect(userID uuid.UUID, in ReflectInput) (*ReflectResult, error) {
	if !s.ai.Configured() {
		return nil, fmt.Errorf("AI not configured")
	}

	summary, err := s.Summary(userID)
	if err != nil {
		return nil, err
	}

	var b strings.Builder
	b.WriteString("Active habits:\n")
	for _, h := range summary.Habits {
		b.WriteString("- " + h.Title + "\n")
	}
	b.WriteString("\nActive targets:\n")
	for _, t := range summary.Targets {
		b.WriteString("- " + t.Title + "\n")
	}
	if in.Notes != "" {
		b.WriteString("\nUser notes:\n" + in.Notes)
	}

	raw, err := s.ai.ChatJSON(userID, "goals/reflect", reflectPrompt, b.String())
	if err != nil {
		return nil, err
	}

	var payload reflectPayload
	if err := json.Unmarshal([]byte(raw), &payload); err != nil {
		return nil, fmt.Errorf("parse AI response: %w", err)
	}

	return &ReflectResult{
		Summary:       payload.Summary,
		Wins:          payload.Wins,
		Blockers:      payload.Blockers,
		FocusNextWeek: payload.FocusNextWeek,
		Encouragement: payload.Encouragement,
		GeneratedAt:   time.Now().UTC(),
	}, nil
}
