package jobscout

import (
	"fmt"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/cv"
)

const maxScanSkills = 10

func scanSkillsForUser(prefs SearchPreferences, profile cv.StackProfile) []string {
	merged := append([]string{}, prefs.FocusSkills...)
	merged = append(merged, profile.PrimaryStack...)
	for _, sk := range profile.AllSkills {
		merged = append(merged, sk)
	}
	out := dedupeStrings(merged)
	if len(out) > maxScanSkills {
		out = out[:maxScanSkills]
	}
	if len(out) == 0 {
		out = defaultSkills()
	}
	return out
}

func (s *Service) refineScanSkills(userID uuid.UUID, profile cv.StackProfile, base []string) []string {
	if s.ai == nil || !s.ai.Configured() || len(base) <= 3 {
		return base
	}

	system := `You pick job-board search keywords from a candidate profile.
Respond with JSON only: {"skills":["skill1","skill2"]}
Rules:
- Return 3-8 skills best suited for IT job board searches (ITviec, TopCV, remote boards).
- Prioritize user focus skills, then strongest CV stack items.
- Use common job-posting terms (e.g. "Spring Boot" not "SB", "Node.js" not "NodeJS").
- No duplicates.`

	prompt := fmt.Sprintf("Focus skills: %s\nCV skills: %s\nCandidate role: %s\nYears: %.1f",
		strings.Join(profile.PrimaryStack, ", "),
		strings.Join(profile.AllSkills, ", "),
		profile.RoleTitle,
		profile.YearsExperience,
	)

	raw, err := s.ai.ChatJSON(userID, "jobs/refine-skills", system, prompt)
	if err != nil {
		return base
	}

	var resp struct {
		Skills []string `json:"skills"`
	}
	if err := parseMatchJSON(raw, &resp); err != nil || len(resp.Skills) == 0 {
		return base
	}
	out := dedupeStrings(append(resp.Skills, base...))
	if len(out) > maxScanSkills {
		out = out[:maxScanSkills]
	}
	return out
}
