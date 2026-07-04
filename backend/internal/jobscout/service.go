package jobscout

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/cv"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/notification"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Service struct {
	db        *gorm.DB
	ai        *ai.Service
	cv        *cv.Service
	notify    *notification.Service
	githubTok string
	scans     *scanTracker

	moduleChecker func(uuid.UUID, string) bool
}

func NewService(db *gorm.DB, aiSvc *ai.Service, cvSvc *cv.Service, notify *notification.Service) *Service {
	return &Service{
		db:        db,
		ai:        aiSvc,
		cv:        cvSvc,
		notify:    notify,
		githubTok: strings.TrimSpace(os.Getenv("GITHUB_TOKEN")),
		scans:     newScanTracker(),
		moduleChecker: func(uuid.UUID, string) bool { return true },
	}
}

func (s *Service) SetModuleChecker(fn func(uuid.UUID, string) bool) {
	if fn != nil {
		s.moduleChecker = fn
	}
}

func (s *Service) moduleEnabled(userID uuid.UUID) bool {
	return s.moduleChecker(userID, models.ModuleWork)
}

type ListOptions struct {
	Status   string
	MinScore float32
	Limit    int
}

func (s *Service) List(userID uuid.UUID, opts ListOptions) ([]models.JobOpportunity, error) {
	status := opts.Status
	if status == "" {
		status = models.JobStatusOpen
	}
	limit := opts.Limit
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	minScore := opts.MinScore
	if status == models.JobStatusOpen && minScore <= 0 {
		minScore = MinMatchScore
	}

	q := s.db.Where("user_id = ? AND status = ?", userID, status)
	if minScore > 0 {
		q = q.Where("match_score >= ?", minScore)
	}

	var rows []models.JobOpportunity
	err := q.Order("match_score DESC, scraped_at DESC").Limit(limit).Find(&rows).Error
	return rows, err
}

func (s *Service) UpdateStatus(userID, jobID uuid.UUID, status string) error {
	res := s.db.Model(&models.JobOpportunity{}).
		Where("id = ? AND user_id = ?", jobID, userID).
		Updates(map[string]any{
			"status":     status,
			"updated_at": time.Now().UTC(),
		})
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (s *Service) Scan(userID uuid.UUID) (*ScanResult, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	_, profile := s.loadCandidateProfile(userID)
	prefs, _ := s.GetPreferences(userID)
	if prefs == nil {
		def := defaultPreferences()
		prefs = &def
	}
	scanSkills := s.refineScanSkills(userID, profile, scanSkillsForUser(*prefs, profile))
	var all []rawJob

	remotive, err := fetchRemotive(ctx)
	if err != nil {
		log.Printf("jobscout: remotive fetch: %v", err)
	} else {
		all = append(all, remotive...)
	}

	remoteOK, err := fetchRemoteOK(ctx)
	if err != nil {
		log.Printf("jobscout: remoteok fetch: %v", err)
	} else {
		all = append(all, remoteOK...)
	}

	githubJobs, err := fetchGitHub(ctx, scanSkills, s.githubTok)
	if err != nil {
		log.Printf("jobscout: github fetch: %v", err)
	} else {
		all = append(all, githubJobs...)
	}

	itviecJobs, err := fetchITviec(ctx, scanSkills)
	if err != nil {
		log.Printf("jobscout: itviec fetch: %v", err)
	} else {
		all = append(all, itviecJobs...)
	}

	topcvJobs, err := fetchTopCV(ctx, scanSkills)
	if err != nil {
		log.Printf("jobscout: topcv fetch: %v", err)
	} else {
		all = append(all, topcvJobs...)
	}

	result := &ScanResult{
		Found:     len(all),
		MinScore:  MinMatchScore,
		ScannedAt: time.Now().UTC(),
	}
	for _, j := range all {
		switch j.Source {
		case "remotive":
			result.Sources.Remotive++
		case "remoteok":
			result.Sources.RemoteOK++
		case "github":
			result.Sources.GitHub++
		case "itviec":
			result.Sources.ITviec++
		case "topcv":
			result.Sources.TopCV++
		}
	}

	type candidate struct {
		job          rawJob
		preScore     float32
		preHits      []string
		primaryMatch bool
	}
	candidates := make([]candidate, 0, len(all))
	for _, j := range all {
		if !jobMatchesPreferences(j, *prefs) {
			continue
		}
		pre, hits, primary := preScoreJob(profile, j)
		if pre >= preFilterMinScore || primary || j.Source == "github" || isVNJobBoardSource(j.Source) {
			candidates = append(candidates, candidate{job: j, preScore: pre, preHits: hits, primaryMatch: primary})
		}
	}
	sort.Slice(candidates, func(i, j int) bool {
		if candidates[i].primaryMatch != candidates[j].primaryMatch {
			return candidates[i].primaryMatch
		}
		return candidates[i].preScore > candidates[j].preScore
	})
	if len(candidates) > maxAICandidates {
		candidates = candidates[:maxAICandidates]
	}

	rawCandidates := make([]rawJob, len(candidates))
	for i, c := range candidates {
		rawCandidates[i] = c.job
	}
	aiScores := s.scoreJobsWithAI(userID, profile, rawCandidates)

	for _, c := range candidates {
		key := c.job.Source + ":" + c.job.ExternalID
		var aiMatch *aiBatchMatch
		if m, ok := aiScores[c.job.ExternalID]; ok {
			copy := m
			aiMatch = &copy
		}
		score, reason := finalizeScore(c.preScore, c.preHits, c.primaryMatch, aiMatch)
		if bonus := preferenceLocationBonus(c.job, *prefs); bonus > 0 && score > 0 {
			score += bonus
			if score > 1 {
				score = 1
			}
		}
		if score < MinMatchScore {
			continue
		}

		skillsJSON, _ := json.Marshal(c.job.Skills)
		row := models.JobOpportunity{
			ID:          uuid.New(),
			UserID:      userID,
			Source:      c.job.Source,
			ExternalID:  c.job.ExternalID,
			Title:       c.job.Title,
			Company:     c.job.Company,
			Location:    c.job.Location,
			URL:         c.job.URL,
			Description: c.job.Description,
			Skills:      datatypes.JSON(skillsJSON),
			MatchScore:  score,
			MatchReason: reason,
			PostedAt:    c.job.PostedAt,
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
			log.Printf("jobscout: store %s: %v", key, res.Error)
			continue
		}
		result.Matched++
		if res.RowsAffected == 1 {
			result.Stored++
		} else {
			result.Updated++
		}
	}

	s.touchLastScan(userID)
	return result, nil
}

func (s *Service) StartScanAsync(userID uuid.UUID) userScanState {
	if s.scans.start(userID) {
		return s.scans.get(userID)
	}
	go func() {
		result, err := s.Scan(userID)
		if err != nil {
			s.scans.fail(userID, err)
			return
		}
		s.scans.complete(userID, result)
	}()
	return s.scans.get(userID)
}

func (s *Service) ScanStatus(userID uuid.UUID) userScanState {
	return s.scans.get(userID)
}

func (s *Service) loadCandidateProfile(userID uuid.UUID) ([]string, cv.StackProfile) {
	profile := s.buildMatchProfile(userID)
	return profile.AllSkills, profile
}

func defaultSkills() []string {
	return []string{
		"Java", "Spring Boot", "AEM", "NestJS", "Node.js", "TypeScript",
		"PostgreSQL", "MongoDB", "Algolia", "Elasticsearch", "GCP", "Docker",
	}
}
