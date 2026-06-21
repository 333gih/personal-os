package learningimport

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/embedding"
	"github.com/personal-os/backend/internal/entity"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
)

const normalizePrompt = `You normalize raw study notes into Personal OS learning domain entries.
Respond with JSON only:
{"type":"learning_course|learning_topic|learning_skill|learning_note","title":"...","content":"2-4 professional sentences","tags":["dsa|english|study"],"metadata":{"track":"dsa|english","phase":"foundation|intermediate|advanced|expert","week":"1-2","level":"beginner|intermediate|advanced","course_slug":"optional-slug"}}`

const coachPrompt = `You are a senior engineering tutor. Given a study topic, return JSON only:
{"summary":"2-3 sentence recap","practice_questions":["q1","q2","q3"],"tips":["tip1","tip2"],"next_steps":["step1","step2"]}`

type Service struct {
	db     *gorm.DB
	ai     *ai.Service
	entity *entity.Service
}

func NewService(db *gorm.DB, aiSvc *ai.Service, embedSvc *embedding.Service) *Service {
	return &Service{db: db, ai: aiSvc, entity: entity.NewService(db, aiSvc, embedSvc)}
}

func (s *Service) GetEntity(userID, id uuid.UUID) (*models.Entity, error) {
	return s.entity.Get(userID, id)
}

type AddInput struct {
	Kind      string
	RawText   string
	TitleHint string
	Track     string
}

type AddResult struct {
	EntityID string `json:"entity_id"`
	Type     string `json:"type"`
	Title    string `json:"title"`
	Content  string `json:"content"`
}

type CoachInput struct {
	EntityID string
	Topic    string
	Track    string
	Focus    string
}

type CoachResult struct {
	Summary           string   `json:"summary"`
	PracticeQuestions []string `json:"practice_questions"`
	Tips              []string `json:"tips"`
	NextSteps         []string `json:"next_steps"`
}

type normalized struct {
	Type     string         `json:"type"`
	Title    string         `json:"title"`
	Content  string         `json:"content"`
	Tags     []string       `json:"tags"`
	Metadata map[string]any `json:"metadata"`
}

type coachPayload struct {
	Summary           string   `json:"summary"`
	PracticeQuestions []string `json:"practice_questions"`
	Tips              []string `json:"tips"`
	NextSteps         []string `json:"next_steps"`
}

func (s *Service) Add(userID uuid.UUID, in AddInput) (*AddResult, error) {
	raw := strings.TrimSpace(in.RawText)
	if raw == "" {
		return nil, fmt.Errorf("raw_text is required")
	}
	if !s.ai.Configured() {
		return nil, fmt.Errorf("AI not configured — set OPENROUTER_API_KEY")
	}
	prompt := fmt.Sprintf("Track hint: %s\nKind hint: %s\nTitle hint: %s\n\nRaw input:\n%s",
		strings.TrimSpace(in.Track), strings.TrimSpace(in.Kind), strings.TrimSpace(in.TitleHint), raw)
	out, err := s.ai.ChatJSON(userID, "learning/add", normalizePrompt, prompt)
	if err != nil {
		return nil, err
	}
	var n normalized
	if err := parseJSON(out, &n); err != nil {
		return nil, err
	}
	entType := mapKind(in.Kind, n.Type)
	tags := n.Tags
	if in.Track != "" {
		tags = appendUnique(tags, strings.ToLower(strings.TrimSpace(in.Track)))
	}
	meta := n.Metadata
	if meta == nil {
		meta = map[string]any{}
	}
	if in.Track != "" && meta["track"] == nil {
		meta["track"] = in.Track
	}
	title := firstNonEmpty(n.Title, in.TitleHint, "Study entry")
	ent, err := s.entity.Create(userID, entity.CreateInput{
		Type:     entType,
		Title:    title,
		Content:  strings.TrimSpace(n.Content),
		Tags:     tags,
		Source:   "learning_add",
		Metadata: meta,
	})
	if err != nil {
		return nil, err
	}
	return &AddResult{
		EntityID: ent.ID.String(),
		Type:     ent.Type,
		Title:    ent.Title,
		Content:  ent.Content,
	}, nil
}

func (s *Service) Coach(userID uuid.UUID, in CoachInput) (*CoachResult, error) {
	if !s.ai.Configured() {
		return nil, fmt.Errorf("AI not configured — set OPENROUTER_API_KEY")
	}
	topic := strings.TrimSpace(in.Topic)
	if in.EntityID != "" {
		eid, err := uuid.Parse(in.EntityID)
		if err == nil {
			if ent, err := s.entity.Get(userID, eid); err == nil {
				topic = ent.Title + "\n" + ent.Content
			}
		}
	}
	if topic == "" {
		return nil, fmt.Errorf("topic or entity_id is required")
	}
	prompt := fmt.Sprintf("Track: %s\nFocus: %s\n\nTopic:\n%s",
		strings.TrimSpace(in.Track), strings.TrimSpace(in.Focus), topic)
	out, err := s.ai.ChatJSON(userID, "learning/coach", coachPrompt, prompt)
	if err != nil {
		return nil, err
	}
	var p coachPayload
	if err := parseJSON(out, &p); err != nil {
		return nil, err
	}
	return &CoachResult{
		Summary:           p.Summary,
		PracticeQuestions: p.PracticeQuestions,
		Tips:              p.Tips,
		NextSteps:         p.NextSteps,
	}, nil
}

func mapKind(hint, aiType string) string {
	h := strings.ToLower(strings.TrimSpace(hint))
	switch h {
	case "course":
		return models.TypeCourse
	case "topic", "module", "pattern":
		return models.TypeTopic
	case "skill":
		return models.TypeSkill
	case "note":
		return models.TypeLearningNote
	}
	t := strings.ToLower(strings.TrimSpace(aiType))
	if strings.Contains(t, "course") {
		return models.TypeCourse
	}
	if strings.Contains(t, "skill") {
		return models.TypeSkill
	}
	if strings.Contains(t, "note") {
		return models.TypeLearningNote
	}
	return models.TypeTopic
}

func parseJSON(raw string, dest any) error {
	raw = strings.TrimSpace(raw)
	if i := strings.Index(raw, "{"); i >= 0 {
		raw = raw[i:]
	}
	if j := strings.LastIndex(raw, "}"); j >= 0 {
		raw = raw[:j+1]
	}
	return json.Unmarshal([]byte(raw), dest)
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if s := strings.TrimSpace(v); s != "" {
			return s
		}
	}
	return ""
}

func appendUnique(tags []string, add ...string) []string {
	seen := map[string]bool{}
	for _, t := range tags {
		seen[strings.ToLower(t)] = true
	}
	for _, a := range add {
		k := strings.ToLower(strings.TrimSpace(a))
		if k == "" || seen[k] {
			continue
		}
		seen[k] = true
		tags = append(tags, k)
	}
	return tags
}
