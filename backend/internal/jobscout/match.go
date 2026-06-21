package jobscout

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/cv"
)

const (
	MinMatchScore       float32 = 0.35
	PrimaryMatchFloor   float32 = 0.85
	maxJobsPerBatch     = 6
	maxAICandidates     = 48
	preFilterMinScore   float32 = 0.05
)

var skillAliases = map[string][]string{
	"java":           {"java", "jvm", "spring"},
	"spring boot":    {"spring boot", "spring-boot", "springboot", "spring"},
	"aem":            {"aem", "adobe experience manager", "adobe cms", "sling", "htl"},
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
	"golang":         {"golang", " go ", "go developer"},
	"python":         {"python", "django", "flask"},
	"angular":        {"angular"},
	"vue":            {"vue", "vuejs"},
	".net":           {".net", "dotnet", "c#"},
	"php":            {"php", "laravel"},
	"ruby":           {"ruby", "rails"},
	"rust":           {"rust"},
	"swift":          {"swift", "swiftui", "ios"},
	"kotlin":         {"kotlin", "android"},
	"aws":            {"aws", "amazon web services"},
	"azure":          {"azure"},
}

type aiBatchMatch struct {
	ExternalID string   `json:"external_id"`
	Score      float32  `json:"score"`
	Reason     string   `json:"reason"`
	Skills     []string `json:"matched_skills"`
}

func preScoreJob(profile cv.StackProfile, job rawJob) (float32, []string, bool) {
	hay := strings.ToLower(job.Title + " " + job.Description + " " + strings.Join(job.Skills, " "))
	if hay == "" {
		return 0, nil, false
	}
	titleHay := strings.ToLower(job.Title)

	var primaryHits, secondaryHits []string
	seen := map[string]bool{}

	for _, skill := range profile.PrimaryStack {
		if hit := matchSkill(skill, hay); hit != "" {
			if !seen[strings.ToLower(hit)] {
				seen[strings.ToLower(hit)] = true
				primaryHits = append(primaryHits, hit)
			}
		}
	}

	for _, skill := range profile.AllSkills {
		if containsSkill(profile.PrimaryStack, skill) {
			continue
		}
		if hit := matchSkill(skill, hay); hit != "" {
			key := strings.ToLower(hit)
			if !seen[key] {
				seen[key] = true
				secondaryHits = append(secondaryHits, hit)
			}
		}
	}

	allHits := append(append([]string{}, primaryHits...), secondaryHits...)
	primaryMatch := len(primaryHits) > 0

	if primaryMatch {
		score := PrimaryMatchFloor + float32(len(primaryHits)-1)*0.05
		for _, p := range profile.PrimaryStack {
			if matchSkill(p, titleHay) != "" {
				score = 0.98
				break
			}
		}
		if score > 1 {
			score = 1
		}
		return score, allHits, true
	}

	if len(secondaryHits) > 0 {
		score := float32(len(secondaryHits)) * 0.12
		if score > 0.72 {
			score = 0.72
		}
		if score < MinMatchScore {
			score = MinMatchScore
		}
		return score, allHits, false
	}

	return 0, nil, false
}

func containsSkill(list []string, skill string) bool {
	skill = strings.ToLower(strings.TrimSpace(skill))
	for _, item := range list {
		if strings.ToLower(strings.TrimSpace(item)) == skill {
			return true
		}
	}
	return false
}

func matchSkill(skill, hay string) string {
	token := strings.ToLower(strings.TrimSpace(skill))
	if token == "" {
		return ""
	}
	if matchSkillInHay(token, hay) {
		return strings.TrimSpace(skill)
	}
	for _, alias := range skillAliases[token] {
		if strings.Contains(hay, alias) {
			return strings.TrimSpace(skill)
		}
	}
	// Parenthetical e.g. "Java (Spring Boot, AEM)"
	if i := strings.Index(token, "("); i > 0 {
		base := strings.TrimSpace(token[:i])
		if base != "" && matchSkillInHay(base, hay) {
			return strings.TrimSpace(skill)
		}
	}
	return ""
}

func matchSkillInHay(skill, hay string) bool {
	if strings.Contains(hay, skill) {
		return true
	}
	compact := strings.ReplaceAll(skill, " ", "")
	if compact != skill && strings.Contains(strings.ReplaceAll(hay, " ", ""), compact) {
		return true
	}
	return false
}

func (s *Service) scoreJobsWithAI(userID uuid.UUID, profile cv.StackProfile, candidates []rawJob) map[string]aiBatchMatch {
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
		matches, err := s.aiScoreBatch(userID, profile, batch)
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

func (s *Service) aiScoreBatch(userID uuid.UUID, profile cv.StackProfile, jobs []rawJob) ([]aiBatchMatch, error) {
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

	system := fmt.Sprintf(`You are a job matching engine. Compare each job to the candidate's MAIN FOCUS skills (user-selected, highest priority).
Respond with JSON only:
{"matches":[{"external_id":"id","score":0-100,"reason":"one sentence","matched_skills":["skill1"]}]}
Rules:
- Candidate profile below includes years, role, focus stack, and work preferences.
- Jobs requiring MAIN FOCUS skills should score 92-100 when title/description align.
- Partial focus overlap: 55-85. Unrelated stack: below 35 — omit.
- Include jobs with score >= 35 in matches array.
- matched_skills lists candidate skills that align with the job.`)

	prompt := fmt.Sprintf("Candidate profile:\n%s\n\nAll CV skills: %s\n\nJobs JSON:\n%s",
		profile.ProfileText, strings.Join(profile.AllSkills, ", "), string(jobsJSON))

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

func finalizeScore(preScore float32, preHits []string, primaryMatch bool, ai *aiBatchMatch) (float32, string) {
	if primaryMatch && preScore >= PrimaryMatchFloor {
		reason := "Primary stack match: " + strings.Join(preHits, ", ")
		if ai != nil && strings.TrimSpace(ai.Reason) != "" {
			score := ai.Score
			if score > 1 {
				score = score / 100
			}
			if score >= PrimaryMatchFloor {
				return score, ai.Reason
			}
		}
		return preScore, reason
	}

	if ai != nil && ai.Score >= MinMatchScore {
		reason := strings.TrimSpace(ai.Reason)
		if reason == "" && len(ai.Skills) > 0 {
			reason = "Matches: " + strings.Join(ai.Skills, ", ")
		}
		score := ai.Score
		if score > 1 {
			score = score / 100
		}
		return score, reason
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
