package jobscout

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
)

const (
	MinMatchScore     float32 = 0.5
	maxJobsPerBatch   = 6
	maxAICandidates   = 24
	preFilterMinScore float32 = 0.08
)

var skillAliases = map[string][]string{
	"java":           {"java", "jvm", "spring"},
	"spring boot":    {"spring boot", "spring-boot", "springboot", "spring"},
	"aem":            {"aem", "adobe experience manager", "adobe cms", "sling"},
	"nestjs":         {"nestjs", "nest.js", "nest js"},
	"node.js":        {"node.js", "nodejs", "node "},
	"postgresql":     {"postgresql", "postgres", "psql"},
	"mongodb":        {"mongodb", "mongo"},
	"algolia":        {"algolia", "search index"},
	"elasticsearch":  {"elasticsearch", "elastic search", "es index"},
	"gcp":            {"gcp", "google cloud", "cloud run"},
	"react":          {"react", "reactjs", "react.js"},
	"typescript":     {"typescript", " ts ", "tsx"},
	"docker":         {"docker", "container"},
	"kubernetes":     {"kubernetes", "k8s"},
	"graphql":        {"graphql", "graph ql"},
	"rabbitmq":       {"rabbitmq", "message queue", "amqp"},
}

type aiBatchMatch struct {
	ExternalID string   `json:"external_id"`
	Score      float32  `json:"score"`
	Reason     string   `json:"reason"`
	Skills     []string `json:"matched_skills"`
}

func preScoreJob(skills []string, job rawJob) (float32, []string) {
	hay := strings.ToLower(job.Title + " " + job.Description + " " + strings.Join(job.Skills, " "))
	if hay == "" {
		return 0, nil
	}

	var hits []string
	seen := map[string]bool{}
	for _, skill := range skills {
		token := strings.ToLower(strings.TrimSpace(skill))
		if token == "" {
			continue
		}
		if matchSkillInHay(token, hay) {
			if !seen[token] {
				seen[token] = true
				hits = append(hits, skill)
			}
			continue
		}
		for _, alias := range skillAliases[token] {
			if strings.Contains(hay, alias) {
				if !seen[token] {
					seen[token] = true
					hits = append(hits, skill)
				}
				break
			}
		}
	}

	if len(hits) == 0 {
		return 0, nil
	}

	denom := len(skills)
	if denom > 6 {
		denom = 6
	}
	if denom < 1 {
		denom = 1
	}
	score := float32(len(hits)) / float32(denom)
	if score > 1 {
		score = 1
	}
	return score, hits
}

func matchSkillInHay(skill, hay string) bool {
	if strings.Contains(hay, skill) {
		return true
	}
	// "Spring Boot" vs springboot
	compact := strings.ReplaceAll(skill, " ", "")
	if compact != skill && strings.Contains(strings.ReplaceAll(hay, " ", ""), compact) {
		return true
	}
	return false
}

func (s *Service) scoreJobsWithAI(userID uuid.UUID, profile string, skills []string, candidates []rawJob) map[string]aiBatchMatch {
	out := map[string]aiBatchMatch{}
	if s.ai == nil || !s.ai.Configured() || len(candidates) == 0 {
		return out
	}

	for i := 0; i < len(candidates); i += maxJobsPerBatch {
		end := i + maxJobsPerBatch
		if end > len(candidates) {
			end = len(candidates)
		}
		batch := candidates[i:end]
		matches, err := s.aiScoreBatch(userID, profile, skills, batch)
		if err != nil {
			continue
		}
		for _, m := range matches {
			if m.ExternalID == "" {
				continue
			}
			if m.Score > 1 {
				m.Score = m.Score / 100
			}
			if m.Score > 1 {
				m.Score = 1
			}
			out[m.ExternalID] = m
		}
	}
	return out
}

func (s *Service) aiScoreBatch(userID uuid.UUID, profile string, skills []string, jobs []rawJob) ([]aiBatchMatch, error) {
	type jobBrief struct {
		ExternalID  string   `json:"external_id"`
		Source      string   `json:"source"`
		Title       string   `json:"title"`
		Company     string   `json:"company"`
		Location    string   `json:"location"`
		Tags        []string `json:"tags,omitempty"`
		Description string   `json:"description"`
	}
	briefs := make([]jobBrief, 0, len(jobs))
	for _, j := range jobs {
		briefs = append(briefs, jobBrief{
			ExternalID:  j.ExternalID,
			Source:      j.Source,
			Title:       j.Title,
			Company:     j.Company,
			Location:    j.Location,
			Tags:        j.Skills,
			Description: trimDesc(j.Description, 700),
		})
	}
	jobsJSON, _ := json.Marshal(briefs)

	system := `You are a job matching engine for a software engineer. Compare each job listing to the candidate profile.
Respond with JSON only:
{"matches":[{"external_id":"id","score":0-100,"reason":"one sentence","matched_skills":["skill1","skill2"]}]}
Rules:
- score is fit percentage 0-100 (skills, role level, stack, domain).
- Only include jobs with score >= 50 in the matches array.
- Be realistic: generic listings with no stack overlap should score below 50.
- matched_skills lists candidate skills that align with the job.`

	prompt := fmt.Sprintf("Candidate profile:\n%s\n\nCV skills: %s\n\nJobs JSON:\n%s",
		profile, strings.Join(skills, ", "), string(jobsJSON))

	raw, err := s.ai.ChatJSON(userID, "jobs/match", system, prompt)
	if err != nil {
		return nil, err
	}

	var resp struct {
		Matches []aiBatchMatch `json:"matches"`
	}
	if err := parseMatchJSON(raw, &resp); err != nil {
		return nil, err
	}
	return resp.Matches, nil
}

func parseMatchJSON(raw string, dest any) error {
	raw = strings.TrimSpace(raw)
	if strings.HasPrefix(raw, "```") {
		raw = strings.TrimPrefix(raw, "```json")
		raw = strings.TrimPrefix(raw, "```")
		if idx := strings.LastIndex(raw, "```"); idx >= 0 {
			raw = raw[:idx]
		}
		raw = strings.TrimSpace(raw)
	}
	start := strings.Index(raw, "{")
	end := strings.LastIndex(raw, "}")
	if start >= 0 && end > start {
		raw = raw[start : end+1]
	}
	return json.Unmarshal([]byte(raw), dest)
}

func finalizeScore(preScore float32, preHits []string, ai *aiBatchMatch) (float32, string) {
	if ai != nil && ai.Score >= MinMatchScore {
		reason := strings.TrimSpace(ai.Reason)
		if reason == "" && len(ai.Skills) > 0 {
			reason = "Matches: " + strings.Join(ai.Skills, ", ")
		}
		return ai.Score, reason
	}

	if preScore >= MinMatchScore {
		return preScore, "Matches: " + strings.Join(preHits, ", ")
	}

	if ai != nil && ai.Score > 0 {
		score := ai.Score
		if score > 1 {
			score = score / 100
		}
		if score >= MinMatchScore {
			return score, ai.Reason
		}
	}
	return 0, ""
}
