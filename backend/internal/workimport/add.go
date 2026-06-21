package workimport

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/entity"
	"github.com/personal-os/backend/internal/models"
)

const addNormalizePrompt = `You normalize raw career/work notes into a professional Personal OS work entry.
Respond with JSON only — no markdown fences.

Schema:
{
  "type": "work_project|work_technology|work_role|work_feature|work_lesson|work_decision",
  "title": "professional title",
  "content": "2-5 polished sentences or bullet-style lines",
  "tags": ["lowercase","tags"],
  "metadata": {
    "company": "optional",
    "period": "optional e.g. 2024 — Present",
    "role": "optional job title",
    "level": "beginner|intermediate|advanced for skills",
    "category": "backend|frontend|cloud|database|other for skills",
    "status": "active|completed for projects"
  },
  "cv_skills": ["optional skill labels to sync to CV"]
}

Rules:
- Rewrite casual input into ATS-friendly, professional language.
- Pick the best type from the requested kind hint when ambiguous.
- For skills/technologies use work_technology with clear category and level.
- cv_skills: 0-6 concise labels when stack/skills are mentioned.`

type AddInput struct {
	Kind     string `json:"kind"`
	RawText  string `json:"raw_text"`
	TitleHint string `json:"title_hint"`
}

type AddResult struct {
	EntityID   string   `json:"entity_id"`
	Type       string   `json:"type"`
	Title      string   `json:"title"`
	Content    string   `json:"content"`
	CVSkillsAdded []string `json:"cv_skills_added,omitempty"`
}

type normalizedEntry struct {
	Type     string         `json:"type"`
	Title    string         `json:"title"`
	Content  string         `json:"content"`
	Tags     []string       `json:"tags"`
	Metadata map[string]any `json:"metadata"`
	CVSkills []string       `json:"cv_skills"`
}

func (s *Service) AddNormalized(userID uuid.UUID, input AddInput) (*AddResult, error) {
	raw := strings.TrimSpace(input.RawText)
	if raw == "" {
		return nil, fmt.Errorf("raw_text is required")
	}
	if !s.ai.Configured() {
		return nil, fmt.Errorf("AI not configured — set OPENROUTER_API_KEY")
	}

	kind := strings.TrimSpace(input.Kind)
	if kind == "" {
		kind = "auto"
	}

	system := addNormalizePrompt
	prompt := fmt.Sprintf("Kind hint: %s\nTitle hint: %s\n\nRaw input:\n%s",
		kind, strings.TrimSpace(input.TitleHint), raw)

	out, err := s.ai.ChatJSON(userID, "work/add", system, prompt)
	if err != nil {
		return nil, err
	}

	var norm normalizedEntry
	if err := parseJSON(out, &norm); err != nil {
		return nil, fmt.Errorf("AI normalize: %w", err)
	}

	entType := mapKindToType(kind, norm.Type)
	title := firstNonEmpty(strings.TrimSpace(norm.Title), strings.TrimSpace(input.TitleHint), "Work entry")
	content := strings.TrimSpace(norm.Content)
	if content == "" {
		content = raw
	}
	meta := norm.Metadata
	if meta == nil {
		meta = map[string]any{}
	}
	tags := norm.Tags
	if tags == nil {
		tags = []string{"work", strings.TrimPrefix(entType, "work_")}
	}

	ent, err := s.entity.Create(userID, entity.CreateInput{
		Type:     entType,
		Title:    title,
		Content:  content,
		Tags:     tags,
		Source:   "work_add",
		Metadata: meta,
	})
	if err != nil {
		return nil, err
	}

	var cvAdded []string
	if s.cv != nil && len(norm.CVSkills) > 0 {
		cvAdded, _ = s.cv.MergeSkills(userID, norm.CVSkills)
	}
	if s.cv != nil && entType == models.TypeTechnology {
		cvAdded2, _ := s.cv.MergeSkills(userID, []string{title})
		cvAdded = append(cvAdded, cvAdded2...)
	}

	return &AddResult{
		EntityID:      ent.ID.String(),
		Type:          entType,
		Title:         title,
		Content:       content,
		CVSkillsAdded: dedupeSlice(cvAdded),
	}, nil
}

func mapKindToType(hint, aiType string) string {
	hint = strings.ToLower(strings.TrimSpace(hint))
	aiType = strings.TrimSpace(aiType)
	if aiType != "" && strings.HasPrefix(aiType, "work_") {
		return aiType
	}
	switch hint {
	case "project":
		return models.TypeWorkProject
	case "skill", "technology", "tech":
		return models.TypeTechnology
	case "role":
		return models.TypeWorkRole
	case "feature":
		return models.TypeWorkFeature
	case "lesson":
		return models.TypeLesson
	case "decision":
		return models.TypeDecision
	default:
		if aiType != "" {
			return aiType
		}
		return models.TypeWorkProject
	}
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

func dedupeSlice(items []string) []string {
	seen := map[string]bool{}
	var out []string
	for _, s := range items {
		s = strings.TrimSpace(s)
		if s == "" || seen[strings.ToLower(s)] {
			continue
		}
		seen[strings.ToLower(s)] = true
		out = append(out, s)
	}
	return out
}
