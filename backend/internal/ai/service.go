package ai

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"github.com/pgvector/pgvector-go"
	"github.com/sashabaranov/go-openai"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Service struct {
	db     *gorm.DB
	client *openai.Client
	model  string
}

type AnalyzeRequest struct {
	EntityID uuid.UUID `json:"entity_id"`
	Action   string    `json:"action"` // classify, summarize, tags, relationships, actions, full
	Content  string    `json:"content"`
	Type     string    `json:"type"`
}

type AnalyzeResult struct {
	Classification   string              `json:"classification,omitempty"`
	SuggestedType    string              `json:"suggested_type,omitempty"`
	Summary          string              `json:"summary,omitempty"`
	Tags             []string            `json:"tags,omitempty"`
	ActionItems      []string            `json:"action_items,omitempty"`
	SuggestedRelations []SuggestedRelation `json:"suggested_relations,omitempty"`
	Insights         string              `json:"insights,omitempty"`
}

type SuggestedRelation struct {
	TargetTitle    string `json:"target_title"`
	RelationType   string `json:"relation_type"`
	Reason         string `json:"reason"`
}

func NewService(db *gorm.DB, baseURL, apiKey, model string) *Service {
	cfg := openai.DefaultConfig(apiKey)
	cfg.BaseURL = strings.TrimSuffix(baseURL, "/")
	client := openai.NewClientWithConfig(cfg)
	return &Service{db: db, client: client, model: model}
}

func (s *Service) Analyze(userID uuid.UUID, entity *models.Entity) (*AnalyzeResult, error) {
	return s.runAnalysis(entity.Title, entity.Content, entity.Type, userID)
}

func (s *Service) AnalyzeRequest(userID uuid.UUID, req AnalyzeRequest) (*AnalyzeResult, error) {
	content := req.Content
	title := ""
	entityType := req.Type

	if req.EntityID != uuid.Nil {
		var entity models.Entity
		if err := s.db.Where("id = ? AND user_id = ?", req.EntityID, userID).First(&entity).Error; err != nil {
			return nil, err
		}
		title = entity.Title
		content = entity.Content
		entityType = entity.Type
	}

	action := req.Action
	if action == "" {
		action = "full"
	}

	switch action {
	case "classify":
		return s.classify(userID, title, content)
	case "summarize":
		return s.summarize(userID, title, content)
	case "tags":
		return s.generateTags(userID, title, content)
	case "relationships":
		return s.suggestRelationships(userID, title, content)
	case "actions":
		return s.generateActions(userID, title, content, entityType)
	default:
		return s.runAnalysis(title, content, entityType, userID)
	}
}

func (s *Service) runAnalysis(title, content, entityType string, userID uuid.UUID) (*AnalyzeResult, error) {
	result := &AnalyzeResult{}

	classify, _ := s.classify(userID, title, content)
	if classify != nil {
		result.Classification = classify.Classification
		result.SuggestedType = classify.SuggestedType
	}

	summary, _ := s.summarize(userID, title, content)
	if summary != nil {
		result.Summary = summary.Summary
	}

	tags, _ := s.generateTags(userID, title, content)
	if tags != nil {
		result.Tags = tags.Tags
	}

	actions, _ := s.generateActions(userID, title, content, entityType)
	if actions != nil {
		result.ActionItems = actions.ActionItems
	}

	rels, _ := s.suggestRelationships(userID, title, content)
	if rels != nil {
		result.SuggestedRelations = rels.SuggestedRelations
	}

	result.Insights = fmt.Sprintf("Entity type: %s. Domain: %s.", entityType, models.DomainForType(entityType))
	return result, nil
}

func (s *Service) classify(userID uuid.UUID, title, content string) (*AnalyzeResult, error) {
	prompt := fmt.Sprintf(`Classify this personal knowledge item. Return JSON only: {"classification":"learning|work|startup|inbox","suggested_type":"specific entity type"}
Title: %s
Content: %s`, title, truncate(content, 2000))

	resp, err := s.chat(userID, "classify", prompt)
	if err != nil {
		return fallbackClassify(title, content), nil
	}
	var result AnalyzeResult
	if json.Unmarshal([]byte(resp), &result) != nil {
		return fallbackClassify(title, content), nil
	}
	return &result, nil
}

func (s *Service) summarize(userID uuid.UUID, title, content string) (*AnalyzeResult, error) {
	prompt := fmt.Sprintf(`Summarize in 2-3 sentences. Return JSON only: {"summary":"..."}
Title: %s
Content: %s`, title, truncate(content, 3000))

	resp, err := s.chat(userID, "summarize", prompt)
	if err != nil {
		return &AnalyzeResult{Summary: truncate(content, 200)}, nil
	}
	var result AnalyzeResult
	if json.Unmarshal([]byte(resp), &result) != nil {
		return &AnalyzeResult{Summary: resp}, nil
	}
	return &result, nil
}

func (s *Service) generateTags(userID uuid.UUID, title, content string) (*AnalyzeResult, error) {
	prompt := fmt.Sprintf(`Generate 3-7 relevant tags. Return JSON only: {"tags":["tag1","tag2"]}
Title: %s
Content: %s`, title, truncate(content, 2000))

	resp, err := s.chat(userID, "tags", prompt)
	if err != nil {
		return &AnalyzeResult{Tags: []string{}}, nil
	}
	var result AnalyzeResult
	if json.Unmarshal([]byte(resp), &result) != nil {
		return &AnalyzeResult{Tags: []string{}}, nil
	}
	return &result, nil
}

func (s *Service) generateActions(userID uuid.UUID, title, content, entityType string) (*AnalyzeResult, error) {
	prompt := fmt.Sprintf(`Generate 3-5 actionable next steps. Return JSON only: {"action_items":["..."]}
Type: %s
Title: %s
Content: %s`, entityType, title, truncate(content, 2000))

	resp, err := s.chat(userID, "actions", prompt)
	if err != nil {
		return &AnalyzeResult{ActionItems: []string{}}, nil
	}
	var result AnalyzeResult
	if json.Unmarshal([]byte(resp), &result) != nil {
		return &AnalyzeResult{ActionItems: []string{}}, nil
	}
	return &result, nil
}

func (s *Service) suggestRelationships(userID uuid.UUID, title, content string) (*AnalyzeResult, error) {
	var entities []models.Entity
	s.db.Where("user_id = ? AND status = 'active'", userID).Order("updated_at DESC").Limit(30).Find(&entities)

	titles := make([]string, len(entities))
	for i, e := range entities {
		titles[i] = fmt.Sprintf("%s (%s)", e.Title, e.Type)
	}

	prompt := fmt.Sprintf(`Given new content and existing entities, suggest relationships. Return JSON only: {"suggested_relations":[{"target_title":"...","relation_type":"used_in|solved|proves|related_to|depends_on","reason":"..."}]}
New: %s - %s
Existing: %s`, title, truncate(content, 500), strings.Join(titles, ", "))

	resp, err := s.chat(userID, "relationships", prompt)
	if err != nil {
		return &AnalyzeResult{SuggestedRelations: []SuggestedRelation{}}, nil
	}
	var result AnalyzeResult
	if json.Unmarshal([]byte(resp), &result) != nil {
		return &AnalyzeResult{SuggestedRelations: []SuggestedRelation{}}, nil
	}
	return &result, nil
}

func (s *Service) Embed(text string) (pgvector.Vector, error) {
	return s.EmbedForUser(uuid.Nil, "embed", text)
}

func (s *Service) EmbedForUser(userID uuid.UUID, endpoint, text string) (pgvector.Vector, error) {
	if s.client == nil || s.model == "" {
		return pgvector.Vector{}, fmt.Errorf("ai not configured")
	}
	start := time.Now()
	resp, err := s.client.CreateEmbeddings(context.Background(), openai.EmbeddingRequestStrings{
		Input: []string{truncate(text, 8000)},
		Model: openai.SmallEmbedding3,
	})
	latency := int(time.Since(start).Milliseconds())
	if err != nil || len(resp.Data) == 0 {
		return pgvector.Vector{}, err
	}
	if userID != uuid.Nil {
		tokens := resp.Usage.TotalTokens
		s.logInteraction(userID, endpoint, string(openai.SmallEmbedding3), tokens, 0, latency)
	}
	return pgvector.NewVector(resp.Data[0].Embedding), nil
}

func (s *Service) chat(userID uuid.UUID, endpoint, prompt string) (string, error) {
	if s.client == nil {
		return "", fmt.Errorf("ai not configured")
	}
	start := time.Now()
	resp, err := s.client.CreateChatCompletion(context.Background(), openai.ChatCompletionRequest{
		Model: s.model,
		Messages: []openai.ChatCompletionMessage{
			{Role: openai.ChatMessageRoleSystem, Content: "You are a personal knowledge assistant. Always respond with valid JSON only."},
			{Role: openai.ChatMessageRoleUser, Content: prompt},
		},
		Temperature: 0.3,
	})
	latency := int(time.Since(start).Milliseconds())
	if err != nil {
		return "", err
	}
	if len(resp.Choices) == 0 {
		return "", fmt.Errorf("empty response")
	}
	if userID != uuid.Nil {
		s.logInteraction(userID, endpoint, s.model, resp.Usage.PromptTokens, resp.Usage.CompletionTokens, latency)
	}
	return strings.TrimSpace(resp.Choices[0].Message.Content), nil
}

func (s *Service) logInteraction(userID uuid.UUID, endpoint, model string, tokensIn, tokensOut, latencyMs int) {
	if s.db == nil || userID == uuid.Nil {
		return
	}
	row := models.AIInteraction{
		UserID:    userID,
		Endpoint:  endpoint,
		Model:     model,
		TokensIn:  tokensIn,
		TokensOut: tokensOut,
		LatencyMs: latencyMs,
	}
	if err := s.db.Create(&row).Error; err != nil {
		return
	}
	total := int64(tokensIn + tokensOut)
	if total == 0 {
		return
	}
	today := time.Now().UTC().Truncate(24 * time.Hour)
	usage := models.ModelUsage{
		UserID: userID,
		Model:  model,
		Date:   today,
		Tokens: total,
	}
	_ = s.db.Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}, {Name: "model"}, {Name: "date"}},
		DoUpdates: clause.Assignments(map[string]any{
			"tokens": gorm.Expr("ai.model_usage.tokens + ?", total),
		}),
	}).Create(&usage).Error
}

func fallbackClassify(title, content string) *AnalyzeResult {
	text := strings.ToLower(title + " " + content)
	classification := "inbox"
	suggestedType := models.TypeInboxNote
	if strings.Contains(text, "course") || strings.Contains(text, "learn") {
		classification = "learning"
		suggestedType = models.TypeCourse
	} else if strings.Contains(text, "project") || strings.Contains(text, "feature") {
		classification = "work"
		suggestedType = models.TypeWorkProject
	} else if strings.Contains(text, "startup") || strings.Contains(text, "business") {
		classification = "startup"
		suggestedType = models.TypeStartupIdea
	}
	return &AnalyzeResult{Classification: classification, SuggestedType: suggestedType}
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "..."
}
