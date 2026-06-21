package workimport

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
)

const interviewDrillPrompt = `You are a senior backend interviewer (Java/Spring/system design). Given an interview topic, return JSON only:
{"warmup_questions":["q1","q2"],"deep_questions":["q1","q2","q3"],"model_answers_outline":["a1","a2"],"follow_up_probes":["p1","p2"],"study_links":["optional extra resource ideas"]}`

type InterviewDrillInput struct {
	EntityID string
	Topic    string
	Stack    string
	Level    string
}

type InterviewDrillResult struct {
	WarmupQuestions     []string `json:"warmup_questions"`
	DeepQuestions       []string `json:"deep_questions"`
	ModelAnswersOutline []string `json:"model_answers_outline"`
	FollowUpProbes      []string `json:"follow_up_probes"`
	StudyLinks          []string `json:"study_links"`
}

type interviewDrillPayload struct {
	WarmupQuestions     []string `json:"warmup_questions"`
	DeepQuestions       []string `json:"deep_questions"`
	ModelAnswersOutline []string `json:"model_answers_outline"`
	FollowUpProbes      []string `json:"follow_up_probes"`
	StudyLinks          []string `json:"study_links"`
}

func (s *Service) InterviewDrill(userID uuid.UUID, in InterviewDrillInput) (*InterviewDrillResult, error) {
	if !s.ai.Configured() {
		return nil, fmt.Errorf("AI not configured — set OPENROUTER_API_KEY")
	}
	topic := strings.TrimSpace(in.Topic)
	var refs []string
	if in.EntityID != "" {
		var ent models.Entity
		if err := s.db.Where("id = ? AND user_id = ?", in.EntityID, userID).First(&ent).Error; err == nil {
			topic = ent.Title + "\n" + ent.Content
			if urls, ok := ent.Metadata["reference_urls"].([]any); ok {
				for _, u := range urls {
					if str, ok := u.(string); ok {
						refs = append(refs, str)
					}
				}
			}
		}
	}
	if topic == "" {
		return nil, fmt.Errorf("topic or entity_id is required")
	}
	level := firstNonEmptyStr(in.Level, "mid-level")
	stack := firstNonEmptyStr(in.Stack, "Java, Spring Boot, PostgreSQL, Kafka")
	prompt := fmt.Sprintf("Candidate level: %s\nPrimary stack: %s\nReference URLs: %s\n\nTopic:\n%s",
		level, stack, strings.Join(refs, ", "), topic)
	out, err := s.ai.ChatJSON(userID, "work/interview/drill", interviewDrillPrompt, prompt)
	if err != nil {
		return nil, err
	}
	var p interviewDrillPayload
	if err := parseInterviewJSON(out, &p); err != nil {
		return nil, err
	}
	return &InterviewDrillResult{
		WarmupQuestions:     p.WarmupQuestions,
		DeepQuestions:       p.DeepQuestions,
		ModelAnswersOutline: p.ModelAnswersOutline,
		FollowUpProbes:      p.FollowUpProbes,
		StudyLinks:          p.StudyLinks,
	}, nil
}

func parseInterviewJSON(raw string, dest any) error {
	raw = strings.TrimSpace(raw)
	if i := strings.Index(raw, "{"); i >= 0 {
		raw = raw[i:]
	}
	if j := strings.LastIndex(raw, "}"); j >= 0 {
		raw = raw[:j+1]
	}
	return json.Unmarshal([]byte(raw), dest)
}

func firstNonEmptyStr(vals ...string) string {
	for _, v := range vals {
		if s := strings.TrimSpace(v); s != "" {
			return s
		}
	}
	return ""
}
