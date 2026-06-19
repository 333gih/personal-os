package search

import (
	"context"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/infrastructure/qdrant"
	"github.com/personal-os/backend/internal/models"
	"github.com/pgvector/pgvector-go"
	"gorm.io/gorm"
)

type Service struct {
	db     *gorm.DB
	ai     *ai.Service
	qdrant *qdrant.Client
}

type Request struct {
	Query  string  `json:"query" binding:"required"`
	Mode   string  `json:"mode"` // fulltext, semantic, hybrid
	Domain string  `json:"domain"`
	Limit  int     `json:"limit"`
}

type Result struct {
	Entity   models.Entity `json:"entity"`
	Score    float64       `json:"score"`
	MatchType string       `json:"match_type"`
}

func NewService(db *gorm.DB, aiSvc *ai.Service, qdrantClient *qdrant.Client) *Service {
	return &Service{db: db, ai: aiSvc, qdrant: qdrantClient}
}

func (s *Service) Search(userID uuid.UUID, req Request) ([]Result, error) {
	mode := req.Mode
	if mode == "" {
		mode = "hybrid"
	}
	limit := req.Limit
	if limit <= 0 || limit > 50 {
		limit = 20
	}

	switch mode {
	case "fulltext":
		return s.fullTextSearch(userID, req.Query, req.Domain, limit)
	case "semantic":
		return s.semanticSearch(userID, req.Query, req.Domain, limit)
	default:
		return s.hybridSearch(userID, req.Query, req.Domain, limit)
	}
}

func (s *Service) fullTextSearch(userID uuid.UUID, query, domain string, limit int) ([]Result, error) {
	tsQuery := strings.Join(strings.Fields(query), " & ")
	sql := `
		SELECT e.*, ts_rank(
			to_tsvector('english', coalesce(title,'') || ' ' || coalesce(content,'')),
			to_tsquery('english', ?)
		) AS score
		FROM entities e
		WHERE user_id = ? AND status = 'active'
		AND to_tsvector('english', coalesce(title,'') || ' ' || coalesce(content,'')) @@ to_tsquery('english', ?)
	`
	args := []any{tsQuery, userID, tsQuery}
	if domain != "" {
		sql += " AND domain = ?"
		args = append(args, domain)
	}
	sql += " ORDER BY score DESC LIMIT ?"
	args = append(args, limit)

	type row struct {
		models.Entity
		Score float64
	}
	var rows []row
	if err := s.db.Raw(sql, args...).Scan(&rows).Error; err != nil {
		return nil, err
	}

	results := make([]Result, len(rows))
	for i, r := range rows {
		results[i] = Result{Entity: r.Entity, Score: r.Score, MatchType: "fulltext"}
	}
	return results, nil
}

func (s *Service) semanticSearch(userID uuid.UUID, query, domain string, limit int) ([]Result, error) {
	if s.ai == nil {
		return nil, fmt.Errorf("semantic search requires AI service")
	}
	vec, err := s.ai.EmbedForUser(userID, "search", query)
	if err != nil {
		return nil, err
	}

	results, err := s.semanticSearchPgvector(userID, vec, domain, limit)
	if err != nil {
		return nil, err
	}

	if s.qdrant != nil && s.qdrant.Enabled() {
		qdrantResults, err := s.semanticSearchQdrant(userID, vec, domain, limit)
		if err == nil {
			results = mergeResults(results, qdrantResults, limit)
		}
	}
	return results, nil
}

func (s *Service) semanticSearchPgvector(userID uuid.UUID, vec pgvector.Vector, domain string, limit int) ([]Result, error) {
	sql := `
		SELECT e.*, 1 - (e.embedding <=> ?) AS score
		FROM entities e
		WHERE user_id = ? AND status = 'active' AND embedding IS NOT NULL
	`
	args := []any{vec, userID}
	if domain != "" {
		sql += " AND domain = ?"
		args = append(args, domain)
	}
	sql += " ORDER BY e.embedding <=> ? LIMIT ?"
	args = append(args, vec, limit)

	type row struct {
		models.Entity
		Score float64
	}
	var rows []row
	if err := s.db.Raw(sql, args...).Scan(&rows).Error; err != nil {
		return nil, err
	}

	results := make([]Result, len(rows))
	for i, r := range rows {
		results[i] = Result{Entity: r.Entity, Score: r.Score, MatchType: "semantic"}
	}
	return results, nil
}

func (s *Service) semanticSearchQdrant(userID uuid.UUID, vec pgvector.Vector, domain string, limit int) ([]Result, error) {
	hits, err := s.qdrant.Search(context.Background(), userID, vec.Slice(), limit)
	if err != nil {
		return nil, err
	}
	results := make([]Result, 0, len(hits))
	for _, hit := range hits {
		entityID, err := uuid.Parse(hit.ID)
		if err != nil {
			continue
		}
		if domain != "" && hit.Payload.EntityType != "" {
			if domainForAIType(hit.Payload.EntityType) != domain {
				continue
			}
		}
		entity, err := s.entityFromQdrantHit(userID, hit.Payload.SourceTable, entityID)
		if err != nil {
			continue
		}
		results = append(results, Result{
			Entity:    *entity,
			Score:     hit.Score,
			MatchType: "semantic",
		})
	}
	return results, nil
}

func (s *Service) entityFromQdrantHit(userID uuid.UUID, sourceTable string, entityID uuid.UUID) (*models.Entity, error) {
	if sourceTable == models.SourceTableReadingProgress {
		var rp models.ReadingProgress
		if err := s.db.Where("id = ? AND user_id = ?", entityID, userID).First(&rp).Error; err != nil {
			return nil, err
		}
		return &models.Entity{
			ID:      rp.ID,
			UserID:  rp.UserID,
			Type:    "entertainment_story",
			Title:   rp.StoryTitle,
			Content: strings.TrimSpace(rp.ChapterTitle + "\n" + rp.CurrentURL),
			Domain:  models.DomainEntertainment,
			Status:  "active",
			Source:  rp.SiteID,
			CreatedAt: rp.CreatedAt,
			UpdatedAt: rp.UpdatedAt,
		}, nil
	}
	var entity models.Entity
	if err := s.db.Where("id = ? AND user_id = ?", entityID, userID).First(&entity).Error; err != nil {
		return nil, err
	}
	return &entity, nil
}

func domainForAIType(aiType string) string {
	switch aiType {
	case models.AITypeLearning:
		return models.DomainLearning
	case models.AITypeStartup:
		return models.DomainStartup
	case models.AITypeGoal:
		return models.DomainGoal
	case models.AITypeJournal:
		return models.DomainJournal
	case models.AITypeBook:
		return models.DomainEntertainment
	default:
		return models.DomainWork
	}
}

func mergeResults(primary, extra []Result, limit int) []Result {
	merged := map[uuid.UUID]Result{}
	for _, r := range primary {
		merged[r.Entity.ID] = r
	}
	for _, r := range extra {
		if existing, ok := merged[r.Entity.ID]; ok {
			if r.Score > existing.Score {
				merged[r.Entity.ID] = r
			}
		} else {
			merged[r.Entity.ID] = r
		}
	}
	out := make([]Result, 0, len(merged))
	for _, r := range merged {
		out = append(out, r)
	}
	for i := 0; i < len(out); i++ {
		for j := i + 1; j < len(out); j++ {
			if out[j].Score > out[i].Score {
				out[i], out[j] = out[j], out[i]
			}
		}
	}
	if len(out) > limit {
		out = out[:limit]
	}
	return out
}

func (s *Service) hybridSearch(userID uuid.UUID, query, domain string, limit int) ([]Result, error) {
	ft, _ := s.fullTextSearch(userID, query, domain, limit)
	sm, _ := s.semanticSearch(userID, query, domain, limit)

	merged := map[uuid.UUID]Result{}
	for _, r := range ft {
		r.Score = r.Score * 0.5
		r.MatchType = "hybrid"
		merged[r.Entity.ID] = r
	}
	for _, r := range sm {
		if existing, ok := merged[r.Entity.ID]; ok {
			existing.Score += r.Score * 0.5
			merged[r.Entity.ID] = existing
		} else {
			r.Score = r.Score * 0.5
			r.MatchType = "hybrid"
			merged[r.Entity.ID] = r
		}
	}

	results := make([]Result, 0, len(merged))
	for _, r := range merged {
		results = append(results, r)
	}
	// simple sort by score desc
	for i := 0; i < len(results); i++ {
		for j := i + 1; j < len(results); j++ {
			if results[j].Score > results[i].Score {
				results[i], results[j] = results[j], results[i]
			}
		}
	}
	if len(results) > limit {
		results = results[:limit]
	}
	return results, nil
}
