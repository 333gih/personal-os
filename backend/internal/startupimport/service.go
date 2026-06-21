package startupimport

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

const normalizePrompt = `You normalize raw startup notes into professional Personal OS startup domain entries.
Respond with JSON only:
{"type":"startup_idea|startup_feature|startup_kpi|startup_competitor|startup_pain_point|startup_business_model","title":"...","content":"2-4 professional sentences","tags":["lowercase"],"metadata":{"stage":"idea|mvp|growth","priority":"low|medium|high","url":"optional"}}`

type Service struct {
	db     *gorm.DB
	ai     *ai.Service
	entity *entity.Service
}

func NewService(db *gorm.DB, aiSvc *ai.Service, embedSvc *embedding.Service) *Service {
	return &Service{db: db, ai: aiSvc, entity: entity.NewService(db, aiSvc, embedSvc)}
}

type AddInput struct {
	Kind      string
	RawText   string
	TitleHint string
}

type AddResult struct {
	EntityID string `json:"entity_id"`
	Type     string `json:"type"`
	Title    string `json:"title"`
	Content  string `json:"content"`
}

type normalized struct {
	Type     string         `json:"type"`
	Title    string         `json:"title"`
	Content  string         `json:"content"`
	Tags     []string       `json:"tags"`
	Metadata map[string]any `json:"metadata"`
}

func (s *Service) Add(userID uuid.UUID, in AddInput) (*AddResult, error) {
	raw := strings.TrimSpace(in.RawText)
	if raw == "" {
		return nil, fmt.Errorf("raw_text is required")
	}
	if !s.ai.Configured() {
		return nil, fmt.Errorf("AI not configured — set OPENROUTER_API_KEY")
	}
	prompt := fmt.Sprintf("Kind hint: %s\nTitle hint: %s\n\nRaw input:\n%s",
		strings.TrimSpace(in.Kind), strings.TrimSpace(in.TitleHint), raw)
	out, err := s.ai.ChatJSON(userID, "startup/add", normalizePrompt, prompt)
	if err != nil {
		return nil, err
	}
	var n normalized
	if err := parseJSON(out, &n); err != nil {
		return nil, err
	}
	entType := mapKind(in.Kind, n.Type)
	title := firstNonEmpty(n.Title, in.TitleHint, "Startup entry")
	ent, err := s.entity.Create(userID, entity.CreateInput{
		Type:     entType,
		Title:    title,
		Content:  strings.TrimSpace(n.Content),
		Tags:     n.Tags,
		Source:   "startup_add",
		Metadata: n.Metadata,
	})
	if err != nil {
		return nil, err
	}
	return &AddResult{EntityID: ent.ID.String(), Type: entType, Title: title, Content: ent.Content}, nil
}

func mapKind(hint, aiType string) string {
	if strings.HasPrefix(strings.TrimSpace(aiType), "startup_") {
		return aiType
	}
	switch strings.ToLower(strings.TrimSpace(hint)) {
	case "feature":
		return models.TypeStartupFeature
	case "kpi":
		return models.TypeKPI
	case "competitor":
		return models.TypeCompetitor
	case "pain", "pain_point":
		return models.TypePainPoint
	case "business", "business_model":
		return models.TypeBusinessModel
	default:
		return models.TypeStartupIdea
	}
}

func firstNonEmpty(vals ...string) string {
	for _, v := range vals {
		if strings.TrimSpace(v) != "" {
			return strings.TrimSpace(v)
		}
	}
	return ""
}

func parseJSON(raw string, dest any) error {
	raw = strings.TrimSpace(raw)
	if strings.HasPrefix(raw, "```") {
		raw = strings.TrimPrefix(raw, "```json")
		raw = strings.TrimPrefix(raw, "```")
		if idx := strings.LastIndex(raw, "```"); idx >= 0 {
			raw = raw[:idx]
		}
	}
	start := strings.Index(raw, "{")
	end := strings.LastIndex(raw, "}")
	if start >= 0 && end > start {
		raw = raw[start : end+1]
	}
	return json.Unmarshal([]byte(raw), dest)
}
