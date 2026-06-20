package jobscout

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/cv"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Service struct {
	db        *gorm.DB
	ai        *ai.Service
	cv        *cv.Service
	githubTok string
}

func NewService(db *gorm.DB, aiSvc *ai.Service, cvSvc *cv.Service) *Service {
	return &Service{
		db:        db,
		ai:        aiSvc,
		cv:        cvSvc,
		githubTok: strings.TrimSpace(os.Getenv("GITHUB_TOKEN")),
	}
}

func (s *Service) List(userID uuid.UUID, limit int) ([]models.JobOpportunity, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	var rows []models.JobOpportunity
	err := s.db.Where("user_id = ? AND status = ?", userID, models.JobStatusOpen).
		Order("match_score DESC, scraped_at DESC").
		Limit(limit).
		Find(&rows).Error
	return rows, err
}

func (s *Service) UpdateStatus(userID, jobID uuid.UUID, status string) error {
	res := s.db.Model(&models.JobOpportunity{}).
		Where("id = ? AND user_id = ?", jobID, userID).
		Update("status", status)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s *Service) Scan(userID uuid.UUID) (*ScanResult, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	skills := s.loadSkills(userID)
	var all []rawJob

	remotive, err := fetchRemotive(ctx)
	if err != nil {
		log.Printf("jobscout: remotive fetch: %v", err)
	} else {
		all = append(all, remotive...)
	}

	githubJobs, err := fetchGitHub(ctx, skills, s.githubTok)
	if err != nil {
		log.Printf("jobscout: github fetch: %v", err)
	} else {
		all = append(all, githubJobs...)
	}

	result := &ScanResult{Found: len(all), ScannedAt: time.Now().UTC()}
	for _, j := range all {
		if j.Source == "remotive" {
			result.Sources.Remotive++
		}
		if j.Source == "github" {
			result.Sources.GitHub++
		}
	}

	for _, j := range all {
		score, reason := scoreJob(skills, j)
		if score < 0.15 && j.Source == "remotive" {
			continue
		}
		skillsJSON, _ := json.Marshal(j.Skills)
		row := models.JobOpportunity{
			ID:          uuid.New(),
			UserID:      userID,
			Source:      j.Source,
			ExternalID:  j.ExternalID,
			Title:       j.Title,
			Company:     j.Company,
			Location:    j.Location,
			URL:         j.URL,
			Description: j.Description,
			Skills:      datatypes.JSON(skillsJSON),
			MatchScore:  score,
			MatchReason: reason,
			PostedAt:    j.PostedAt,
			ScrapedAt:   time.Now().UTC(),
			Status:      models.JobStatusOpen,
		}
		res := s.db.Clauses(clause.OnConflict{
			Columns: []clause.Column{{Name: "user_id"}, {Name: "source"}, {Name: "external_id"}},
			DoUpdates: clause.Assignments(map[string]any{
				"title":        row.Title,
				"company":      row.Company,
				"location":     row.Location,
				"url":          row.URL,
				"description":  row.Description,
				"skills":       row.Skills,
				"match_score":  row.MatchScore,
				"match_reason": row.MatchReason,
				"posted_at":    row.PostedAt,
				"scraped_at":   row.ScrapedAt,
				"updated_at":   time.Now().UTC(),
			}),
		}).Create(&row)
		if res.Error != nil {
			continue
		}
		if res.RowsAffected == 1 {
			result.Stored++
		} else {
			result.Updated++
		}
	}

	if s.ai != nil && s.ai.Configured() {
		s.enrichTopMatches(userID, skills)
	}

	return result, nil
}

func (s *Service) loadSkills(userID uuid.UUID) []string {
	if s.cv == nil {
		return defaultSkills()
	}
	doc, err := s.cv.Get(userID)
	if err != nil || len(doc.Document.Skills) == 0 {
		return defaultSkills()
	}
	return doc.Document.Skills
}

func defaultSkills() []string {
	return []string{"Java", "Spring Boot", "AEM", "NestJS", "Node.js", "PostgreSQL", "Algolia"}
}

func scoreJob(skills []string, job rawJob) (float32, string) {
	hay := strings.ToLower(job.Title + " " + job.Description + " " + strings.Join(job.Skills, " "))
	if hay == "" {
		return 0, ""
	}
	var hits []string
	for _, skill := range skills {
		token := strings.ToLower(strings.TrimSpace(skill))
		if token == "" {
			continue
		}
		if strings.Contains(hay, token) {
			hits = append(hits, skill)
		}
	}
	if len(hits) == 0 {
		return 0.1, "Broad listing — review manually"
	}
	score := float32(len(hits)) / float32(len(skills))
	if score > 1 {
		score = 1
	}
	if score < 0.2 {
		score = 0.2
	}
	return score, "Matches: " + strings.Join(hits, ", ")
}

func (s *Service) enrichTopMatches(userID uuid.UUID, skills []string) {
	var rows []models.JobOpportunity
	if err := s.db.Where("user_id = ? AND status = ?", userID, models.JobStatusOpen).
		Order("match_score DESC").Limit(8).Find(&rows).Error; err != nil {
		return
	}
	for i := range rows {
		prompt := fmt.Sprintf("Skills: %s\nJob: %s at %s\nDescription excerpt: %s\nReturn JSON: {\"match_reason\":\"one sentence why this fits\"}",
			strings.Join(skills, ", "), rows[i].Title, rows[i].Company, trimDesc(rows[i].Description, 600))
		raw, err := s.ai.ChatJSON(userID, "jobs/match", "You are a career coach matching jobs to a software engineer CV.", prompt)
		if err != nil {
			continue
		}
		var out struct {
			MatchReason string `json:"match_reason"`
		}
		if json.Unmarshal([]byte(raw), &out) == nil && out.MatchReason != "" {
			s.db.Model(&rows[i]).Update("match_reason", out.MatchReason)
		}
	}
}

func (s *Service) StartDailyWorker(ctx context.Context, interval time.Duration) {
	if interval <= 0 {
		interval = 24 * time.Hour
	}
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	log.Printf("jobscout: daily worker started (interval=%s)", interval)
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.scanAllUsers()
		}
	}
}

func (s *Service) scanAllUsers() {
	var userIDs []uuid.UUID
	if err := s.db.Model(&models.User{}).Pluck("id", &userIDs).Error; err != nil {
		return
	}
	for _, id := range userIDs {
		if _, err := s.Scan(id); err != nil {
			log.Printf("jobscout: scan user %s: %v", id, err)
		}
	}
}
