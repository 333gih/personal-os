package studylearning

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

type LessonModule struct {
	ID           string `json:"id"`
	Title        string `json:"title"`
	Subtitle     string `json:"subtitle,omitempty"`
	PatternOrder int    `json:"pattern_order,omitempty"`
	Phase        string `json:"phase,omitempty"`
}

type PracticeMode struct {
	ID              string `json:"id"`
	Title           string `json:"title"`
	Subtitle        string `json:"subtitle"`
	DurationMinutes int    `json:"duration_minutes"`
	Focus           string `json:"focus"`
	Async           bool   `json:"async"`
}

type LearningLesson struct {
	EntityID           string         `json:"entity_id"`
	Title              string         `json:"title"`
	Content            string         `json:"content"`
	Type               string         `json:"type"`
	Track              string         `json:"track"`
	Phase              string         `json:"phase,omitempty"`
	Weeks              string         `json:"weeks,omitempty"`
	PatternOrder       int            `json:"pattern_order,omitempty"`
	WhenToUse          string         `json:"when_to_use,omitempty"`
	RecognitionSignals []string       `json:"recognition_signals,omitempty"`
	PracticeStrategy   string         `json:"practice_strategy,omitempty"`
	CodeTemplate       string         `json:"code_template,omitempty"`
	Problems           []string       `json:"problems,omitempty"`
	Benchmarks         DSABenchmarks  `json:"benchmarks,omitempty"`
	Modules            []LessonModule `json:"modules,omitempty"`
	PracticeModes      []PracticeMode `json:"practice_modes"`
	CurriculumWeek     int            `json:"curriculum_week,omitempty"`
}

func (s *Service) GetLesson(userID, entityID uuid.UUID) (*LearningLesson, error) {
	ent, err := s.learningEntity(userID, entityID)
	if err != nil {
		return nil, err
	}
	meta := map[string]any(ent.Metadata)
	track := metaString(meta, "track")
	if track == "" {
		track = inferTrack(*ent)
	}

	lesson := &LearningLesson{
		EntityID:           ent.ID.String(),
		Title:              ent.Title,
		Content:            ent.Content,
		Type:               ent.Type,
		Track:              track,
		Phase:              metaString(meta, "phase"),
		Weeks:              metaString(meta, "weeks", "week"),
		PatternOrder:       metaInt(meta, "pattern_order"),
		WhenToUse:          metaString(meta, "when_to_use"),
		RecognitionSignals: metaStringSlice(meta, "recognition_signals"),
		PracticeStrategy:   metaString(meta, "practice_strategy"),
		CodeTemplate:       metaString(meta, "code_template"),
		Problems:           metaStringSlice(meta, "problems"),
		Benchmarks: DSABenchmarks{
			EasyMinutes:   metaInt(meta, "benchmark_easy_min"),
			MediumMinutes: metaInt(meta, "benchmark_medium_min"),
			HardMinutes:   metaInt(meta, "benchmark_hard_min"),
		},
		CurriculumWeek: patternCurriculumWeek(metaInt(meta, "pattern_order")),
	}

	if strings.Contains(ent.Type, "course") {
		lesson.Modules = s.listModules(userID, track, metaString(meta, "course_slug"))
		lesson.PracticeModes = coursePracticeModes(track)
	} else {
		lesson.PracticeModes = topicPracticeModes(track, lesson.PatternOrder, lesson.Problems)
	}

	if lesson.Benchmarks.EasyMinutes == 0 && track == "dsa" {
		lesson.Benchmarks = DSABenchmarks{EasyMinutes: 8, MediumMinutes: 20, HardMinutes: 35}
	}
	return lesson, nil
}

func (s *Service) learningEntity(userID, id uuid.UUID) (*models.Entity, error) {
	var ent models.Entity
	err := s.db.Omit("embedding").Where("id = ? AND user_id = ?", id, userID).First(&ent).Error
	if err == nil {
		return &ent, nil
	}
	if err != gorm.ErrRecordNotFound {
		return nil, err
	}
	if !strings.HasPrefix(id.String(), "c000000c-0001-4001-8001-") {
		return nil, gorm.ErrRecordNotFound
	}
	if err := s.db.Omit("embedding").Where("id = ?", id).First(&ent).Error; err != nil {
		return nil, err
	}
	if ent.Domain != models.DomainLearning {
		return nil, gorm.ErrRecordNotFound
	}
	if ent.UserID != userID {
		s.db.Model(&ent).Update("user_id", userID)
		ent.UserID = userID
	}
	return &ent, nil
}

func (s *Service) listModules(userID uuid.UUID, track, courseSlug string) []LessonModule {
	var rows []models.Entity
	q := s.db.Omit("embedding").
		Where("user_id = ? AND domain = ? AND status = 'active'", userID, models.DomainLearning).
		Where("type LIKE ?", "learning_%")
	if track == "english" && courseSlug != "" {
		q = q.Where("metadata->>'course_slug' = ?", courseSlug)
	} else if track == "dsa" {
		q = q.Where("(metadata->>'pattern_order') IS NOT NULL")
	} else if track != "" {
		q = q.Where("metadata->>'track' = ?", track)
	}
	if err := q.Find(&rows).Error; err != nil {
		return nil
	}

	modules := make([]LessonModule, 0, len(rows))
	for _, row := range rows {
		meta := map[string]any(row.Metadata)
		order := metaInt(meta, "pattern_order")
		if track == "dsa" && order == 0 {
			continue
		}
		if strings.Contains(row.Type, "course") {
			continue
		}
		sub := metaString(meta, "when_to_use")
		if sub == "" {
			sub = trimPreview(row.Content, 120)
		}
		modules = append(modules, LessonModule{
			ID:           row.ID.String(),
			Title:        row.Title,
			Subtitle:     sub,
			PatternOrder: order,
			Phase:        metaString(meta, "phase"),
		})
	}
	sort.Slice(modules, func(i, j int) bool {
		if modules[i].PatternOrder != modules[j].PatternOrder {
			return modules[i].PatternOrder < modules[j].PatternOrder
		}
		return modules[i].Title < modules[j].Title
	})
	return modules
}

func coursePracticeModes(track string) []PracticeMode {
	if track == "english" {
		return []PracticeMode{
			{ID: "vocab_flash", Title: "Vocab flash", Subtitle: "10 words · definition → sentence", DurationMinutes: 5, Focus: "toeic vocabulary flash", Async: false},
			{ID: "grammar_drill", Title: "Grammar drill", Subtitle: "Part 5 traps", DurationMinutes: 10, Focus: "toeic grammar part 5", Async: false},
			{ID: "listening", Title: "Listening sprint", Subtitle: "Part 3–4 patterns", DurationMinutes: 15, Focus: "toeic listening", Async: true},
		}
	}
	return []PracticeMode{
		{ID: "roadmap_review", Title: "Roadmap check-in", Subtitle: "Where am I in the 10-week plan?", DurationMinutes: 5, Focus: "10-week DSA roadmap progress", Async: false},
		{ID: "pattern_pick", Title: "Pick today's pattern", Subtitle: "Open daily focus pattern", DurationMinutes: 25, Focus: "daily DSA pattern from program", Async: false},
		{ID: "mock_block", Title: "Weekend mock", Subtitle: "Timed medium + hard pair", DurationMinutes: 45, Focus: "timed mock interview block", Async: true},
	}
}

func topicPracticeModes(track string, patternOrder int, problems []string) []PracticeMode {
	if track == "english" {
		return []PracticeMode{
			{ID: "recall", Title: "Active recall", Subtitle: "Explain rule without notes", DurationMinutes: 5, Focus: "active recall", Async: false},
			{ID: "examples", Title: "Example sentences", Subtitle: "Write 3 professional sentences", DurationMinutes: 10, Focus: "production practice", Async: false},
			{ID: "coach", Title: "AI drill", Subtitle: "Background coach job", DurationMinutes: 15, Focus: "deep practice", Async: true},
		}
	}
	probHint := "from curated list"
	if len(problems) > 0 {
		probHint = fmt.Sprintf("start with %s", problems[0])
	}
	_ = patternOrder
	return []PracticeMode{
		{ID: "flash", Title: "Metro flash", Subtitle: "Recall signals + template · 2 min", DurationMinutes: 2, Focus: "pattern flash recall — recognition signals and steps only, no code", Async: false},
		{ID: "easy", Title: "Easy warm-up", Subtitle: probHint, DurationMinutes: 8, Focus: "one easy LeetCode — outline approach then code", Async: false},
		{ID: "medium", Title: "Timed medium", Subtitle: "20 min cap · hints after 5 min", DurationMinutes: 20, Focus: "one medium LeetCode timed — pattern application", Async: false},
		{ID: "review", Title: "Spaced review", Subtitle: "Re-solve without notes", DurationMinutes: 15, Focus: "spaced repetition — re-derive solution", Async: false},
		{ID: "coach", Title: "AI coach deep", Subtitle: "Full walkthrough + follow-ups", DurationMinutes: 25, Focus: "deep coach walkthrough with edge cases", Async: true},
	}
}

func patternCurriculumWeek(order int) int {
	if order <= 0 {
		return 0
	}
	for week, orders := range weekPatternOrders {
		for _, o := range orders {
			if o == order {
				return week
			}
		}
	}
	return 0
}

func inferTrack(ent models.Entity) string {
	var tags []string
	_ = json.Unmarshal(ent.Tags, &tags)
	for _, t := range tags {
		if t == "dsa" || t == "english" {
			return t
		}
	}
	return ""
}

func metaString(meta map[string]any, keys ...string) string {
	for _, key := range keys {
		if v, ok := meta[key]; ok {
			switch t := v.(type) {
			case string:
				if s := strings.TrimSpace(t); s != "" {
					return s
				}
			}
		}
	}
	return ""
}

func metaInt(meta map[string]any, key string) int {
	v, ok := meta[key]
	if !ok {
		return 0
	}
	switch t := v.(type) {
	case float64:
		return int(t)
	case int:
		return t
	case json.Number:
		n, _ := t.Int64()
		return int(n)
	}
	return 0
}

func metaStringSlice(meta map[string]any, key string) []string {
	v, ok := meta[key]
	if !ok {
		return nil
	}
	switch t := v.(type) {
	case []string:
		return t
	case []any:
		out := make([]string, 0, len(t))
		for _, item := range t {
			if s, ok := item.(string); ok && strings.TrimSpace(s) != "" {
				out = append(out, strings.TrimSpace(s))
			}
		}
		return out
	}
	return nil
}

func trimPreview(s string, max int) string {
	s = strings.TrimSpace(s)
	if len(s) <= max {
		return s
	}
	return s[:max] + "…"
}
