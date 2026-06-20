package cv

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/google/uuid"
)

func defaultSkillGroups() []SkillGroup {
	return []SkillGroup{
		{Category: "Backend & APIs", Items: []string{"Java (Spring Boot, AEM)", "Node.js (NestJS)", "Golang", "gRPC", "WebSocket"}},
		{Category: "Frontend", Items: []string{"ReactJS", "NextJS", "Thymeleaf", "HTL"}},
		{Category: "Database & Caching", Items: []string{"PostgreSQL", "MySQL", "Oracle", "MongoDB", "Redis"}},
		{Category: "Search Engine", Items: []string{"ElasticSearch", "Algolia"}},
		{Category: "AI & Tooling", Items: []string{"GitHub Copilot", "Cursor AI", "Claude AI", "ChatGPT"}},
		{Category: "Scalability & Performance", Items: []string{"Microservices", "Kafka", "RabbitMQ", "Distributed Systems"}},
		{Category: "Cloud", Items: []string{"Google Cloud", "AEM Cloud"}},
	}
}

func (s *Service) SuggestSkills(userID uuid.UUID) (*SuggestSkillsResponse, error) {
	cvDoc, err := s.Get(userID)
	if err != nil {
		return nil, err
	}
	doc := cvDoc.Document
	NormalizeDocument(&doc)
	profile := BuildStackProfile(doc)

	resp := &SuggestSkillsResponse{PrimaryStack: profile.PrimaryStack}
	if !s.ai.Configured() {
		resp.Suggestions = ruleBasedSuggestions(doc, profile)
		return resp, nil
	}

	system := `You suggest resume skills for a software engineer. Respond with JSON only:
{"suggestions":[{"category":"Backend & APIs","skill":"Kafka","reason":"short why"}]}
Rules:
- Suggest 5-10 skills the candidate likely has or should highlight based on their CV.
- Use existing skill group categories when possible (Backend & APIs, Frontend, Database & Caching, Search Engine, AI & Tooling, Scalability & Performance, Cloud).
- Do not repeat skills already in the CV.
- Tailor to the candidate's primary stack — not a fixed technology list.`

	prompt := fmt.Sprintf("Primary stack: %s\nYears experience: %.1f\nRole: %s\n\nCV summary:\n%s\n\nExisting skills:\n%s",
		strings.Join(profile.PrimaryStack, ", "),
		profile.YearsExperience,
		profile.RoleTitle,
		doc.Summary,
		strings.Join(profile.AllSkills, ", "))

	raw, err := s.ai.ChatJSON(userID, "cv/suggest-skills", system, prompt)
	if err != nil {
		resp.Suggestions = ruleBasedSuggestions(doc, profile)
		return resp, nil
	}

	var aiResp struct {
		Suggestions []SuggestedSkill `json:"suggestions"`
	}
	if err := json.Unmarshal([]byte(raw), &aiResp); err != nil {
		resp.Suggestions = ruleBasedSuggestions(doc, profile)
		return resp, nil
	}
	resp.Suggestions = filterNewSuggestions(doc, aiResp.Suggestions)
	if len(resp.Suggestions) == 0 {
		resp.Suggestions = ruleBasedSuggestions(doc, profile)
	}
	return resp, nil
}

func (s *Service) AddSkill(userID uuid.UUID, req AddSkillRequest) (*AddSkillResponse, error) {
	cvDoc, err := s.Get(userID)
	if err != nil {
		return nil, err
	}
	doc := cvDoc.Document
	NormalizeDocument(&doc)

	skill := strings.TrimSpace(req.Skill)
	category := strings.TrimSpace(req.Category)
	if skill == "" || category == "" {
		return nil, fmt.Errorf("category and skill are required")
	}

	existing := map[string]bool{}
	for _, sk := range AllSkills(doc) {
		existing[strings.ToLower(sk)] = true
	}
	if existing[strings.ToLower(skill)] {
		return &AddSkillResponse{Added: nil, Document: doc}, nil
	}

	idx := -1
	for i, g := range doc.SkillGroups {
		if strings.EqualFold(g.Category, category) {
			idx = i
			break
		}
	}
	if idx >= 0 {
		doc.SkillGroups[idx].Items = append(doc.SkillGroups[idx].Items, skill)
	} else {
		doc.SkillGroups = append(doc.SkillGroups, SkillGroup{Category: category, Items: []string{skill}})
	}
	doc.Skills = AllSkills(doc)

	saved, err := s.Save(userID, doc)
	if err != nil {
		return nil, err
	}
	return &AddSkillResponse{Added: []string{skill}, Document: saved.Document}, nil
}

func ruleBasedSuggestions(doc CVDocument, profile StackProfile) []SuggestedSkill {
	existing := map[string]bool{}
	for _, sk := range AllSkills(doc) {
		existing[strings.ToLower(sk)] = true
	}

	candidates := []SuggestedSkill{
		{Category: "Scalability & Performance", Skill: "Kafka", Reason: "Common with Java microservices"},
		{Category: "Scalability & Performance", Skill: "Docker", Reason: "Standard for backend delivery"},
		{Category: "Cloud", Skill: "Kubernetes", Reason: "Natural next step for cloud-native roles"},
		{Category: "Backend & APIs", Skill: "REST API", Reason: "Highlight API design experience"},
		{Category: "Database & Caching", Skill: "Redis", Reason: "Performance caching for backend systems"},
	}

	for _, primary := range profile.PrimaryStack {
		p := strings.ToLower(primary)
		switch {
		case strings.Contains(p, "java") || strings.Contains(p, "spring"):
			candidates = append(candidates,
				SuggestedSkill{Category: "Backend & APIs", Skill: "JUnit", Reason: "Java testing standard"},
				SuggestedSkill{Category: "Backend & APIs", Skill: "Maven", Reason: "Java build tooling"},
			)
		case strings.Contains(p, "aem"):
			candidates = append(candidates,
				SuggestedSkill{Category: "Backend & APIs", Skill: "OSGi", Reason: "AEM component development"},
				SuggestedSkill{Category: "Frontend", Skill: "HTL", Reason: "AEM templating"},
			)
		case strings.Contains(p, "node") || strings.Contains(p, "nest"):
			candidates = append(candidates,
				SuggestedSkill{Category: "Backend & APIs", Skill: "TypeScript", Reason: "NestJS ecosystem"},
				SuggestedSkill{Category: "Database & Caching", Skill: "MongoDB", Reason: "Common with Node backends"},
			)
		case strings.Contains(p, "react"):
			candidates = append(candidates,
				SuggestedSkill{Category: "Frontend", Skill: "TypeScript", Reason: "Modern React stack"},
				SuggestedSkill{Category: "Frontend", Skill: "Tailwind CSS", Reason: "Popular UI tooling"},
			)
		}
	}

	return filterNewSuggestions(doc, candidates)
}

func filterNewSuggestions(doc CVDocument, items []SuggestedSkill) []SuggestedSkill {
	existing := map[string]bool{}
	for _, sk := range AllSkills(doc) {
		existing[strings.ToLower(strings.TrimSpace(sk))] = true
	}
	var out []SuggestedSkill
	seen := map[string]bool{}
	for _, item := range items {
		skill := strings.TrimSpace(item.Skill)
		category := strings.TrimSpace(item.Category)
		if skill == "" || category == "" {
			continue
		}
		key := strings.ToLower(skill)
		if existing[key] || seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, SuggestedSkill{Category: category, Skill: skill, Reason: strings.TrimSpace(item.Reason)})
	}
	return out
}
