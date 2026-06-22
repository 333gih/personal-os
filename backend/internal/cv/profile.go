package cv

import (
	"regexp"
	"sort"
	"strings"
)

// StackProfile is derived from the user's CV for job matching and skill suggestions.
type StackProfile struct {
	PrimaryStack    []string
	AllSkills       []string
	YearsExperience float32
	ProfileText     string
	RoleTitle       string
}

var stackFamilyLabels = map[string]string{
	"java":       "Java",
	"spring":     "Spring Boot",
	"aem":        "AEM",
	"node":       "Node.js",
	"nestjs":     "NestJS",
	"golang":     "Golang",
	"python":     "Python",
	"react":      "React",
	"angular":    "Angular",
	"vue":        "Vue",
	"dotnet":     ".NET",
	"php":        "PHP",
	"ruby":       "Ruby",
	"rust":       "Rust",
	"swift":      "Swift",
	"kotlin":     "Kotlin",
	"typescript": "TypeScript",
	"aws":        "AWS",
	"gcp":        "GCP",
	"azure":      "Azure",
}

var stackFamilyKeywords = map[string][]string{
	"java":       {"java", "jvm", "spring boot", "springboot", "spring", "maven", "gradle", "hibernate"},
	"spring":     {"spring boot", "springboot", "spring framework", "spring"},
	"aem":        {"aem", "adobe experience manager", "adobe cms", "sling", "htl", "adobe cloud"},
	"node":       {"node.js", "nodejs", "node "},
	"nestjs":     {"nestjs", "nest.js", "nest js"},
	"golang":     {"golang", "go lang", " go "},
	"python":     {"python", "django", "flask", "fastapi"},
	"react":      {"react", "reactjs", "react.js", "nextjs", "next.js"},
	"angular":    {"angular"},
	"vue":        {"vue", "vuejs", "nuxt"},
	"dotnet":     {".net", "dotnet", "c#", "asp.net"},
	"php":        {"php", "laravel", "symfony"},
	"ruby":       {"ruby", "rails"},
	"rust":       {"rust"},
	"swift":      {"swift", "swiftui", "ios"},
	"kotlin":     {"kotlin", "android"},
	"typescript": {"typescript", " ts "},
	"aws":        {"aws", "amazon web services", "lambda", "ec2"},
	"gcp":        {"gcp", "google cloud", "cloud run"},
	"azure":      {"azure", "microsoft cloud"},
}

// AllSkills returns a deduplicated flat list from skill groups and legacy skills.
func AllSkills(doc CVDocument) []string {
	seen := map[string]bool{}
	var out []string
	add := func(s string) {
		s = strings.TrimSpace(s)
		if s == "" {
			return
		}
		key := strings.ToLower(s)
		if seen[key] {
			return
		}
		seen[key] = true
		out = append(out, s)
	}
	for _, g := range doc.SkillGroups {
		for _, item := range g.Items {
			add(item)
		}
	}
	for _, s := range doc.Skills {
		add(s)
	}
	return out
}

// NormalizeDocument fills derived fields and keeps skill_groups in sync with flat skills.
func NormalizeDocument(doc *CVDocument) {
	if len(doc.SkillGroups) == 0 && len(doc.Skills) > 0 {
		doc.SkillGroups = []SkillGroup{{Category: "Skills", Items: append([]string(nil), doc.Skills...)}}
	}
	doc.Skills = AllSkills(*doc)
	if len(doc.PrimaryStack) == 0 {
		doc.PrimaryStack = inferPrimaryStack(*doc)
	}
	if doc.YearsExperience <= 0 {
		doc.YearsExperience = inferYearsExperience(*doc)
	}
}

func BuildStackProfile(doc CVDocument) StackProfile {
	NormalizeDocument(&doc)
	all := AllSkills(doc)
	primary := doc.PrimaryStack
	if len(primary) == 0 {
		primary = inferPrimaryStack(doc)
	}

	var parts []string
	if doc.Headline != "" {
		parts = append(parts, doc.Headline)
	}
	if doc.Summary != "" {
		parts = append(parts, doc.Summary)
	}
	for _, exp := range doc.Experience {
		if exp.Title != "" {
			parts = append(parts, exp.Title)
		}
		if exp.Content != "" {
			parts = append(parts, exp.Content)
		}
	}
	for _, proj := range doc.Projects {
		if proj.Title != "" {
			parts = append(parts, proj.Title)
		}
		if proj.Content != "" {
			parts = append(parts, proj.Content)
		}
	}
	for _, a := range doc.Achievements {
		if strings.TrimSpace(a.Content) != "" {
			parts = append(parts, a.Content)
		}
	}

	role := splitHeadlineRole(doc.Headline)
	years := doc.YearsExperience
	if years <= 0 {
		years = inferYearsExperience(doc)
	}

	return StackProfile{
		PrimaryStack:    primary,
		AllSkills:       all,
		YearsExperience: years,
		ProfileText:     strings.Join(parts, "\n"),
		RoleTitle:       role,
	}
}

func inferPrimaryStack(doc CVDocument) []string {
	if len(doc.PrimaryStack) > 0 {
		return doc.PrimaryStack
	}

	scores := map[string]int{}
	text := strings.ToLower(doc.Headline + " " + doc.Summary + " " + joinExperienceText(doc) + " " + joinProjectsText(doc))

	for family, keywords := range stackFamilyKeywords {
		for _, kw := range keywords {
			if strings.Contains(text, kw) {
				scores[family] += 2
			}
		}
	}

	// Boost from first backend skill group items.
	for _, g := range doc.SkillGroups {
		cat := strings.ToLower(g.Category)
		if strings.Contains(cat, "backend") || strings.Contains(cat, "api") {
			for i, item := range g.Items {
				if i >= 4 {
					break
				}
				bumpFamilyScores(scores, strings.ToLower(item))
			}
			break
		}
	}

	type ranked struct {
		family string
		score  int
	}
	var list []ranked
	for f, s := range scores {
		if s > 0 {
			list = append(list, ranked{f, s})
		}
	}
	sort.Slice(list, func(i, j int) bool {
		if list[i].score == list[j].score {
			return list[i].family < list[j].family
		}
		return list[i].score > list[j].score
	})

	seen := map[string]bool{}
	var out []string
	for _, r := range list {
		label := stackFamilyLabels[r.family]
		if label == "" {
			continue
		}
		key := strings.ToLower(label)
		if seen[key] {
			continue
		}
		seen[key] = true
		out = append(out, label)
		if len(out) >= 4 {
			break
		}
	}

	if len(out) == 0 {
		all := AllSkills(doc)
		if len(all) > 3 {
			out = append(out, all[:3]...)
		} else {
			out = append(out, all...)
		}
	}
	return out
}

func bumpFamilyScores(scores map[string]int, item string) {
	for family, keywords := range stackFamilyKeywords {
		for _, kw := range keywords {
			if strings.Contains(item, kw) || strings.Contains(kw, item) {
				scores[family] += 3
			}
		}
	}
}

func inferYearsExperience(doc CVDocument) float32 {
	text := joinExperienceText(doc)
	re := regexp.MustCompile(`(?i)(\d{4})\s*(?:—|–|-|to|–)\s*(?:present|now|(\d{4}))`)
	matches := re.FindAllStringSubmatch(text, -1)
	if len(matches) == 0 {
		return 3
	}
	minYear := 9999
	maxYear := 0
	for _, m := range matches {
		start := parseYear(m[1])
		end := parseYear(m[2])
		if end == 0 {
			end = 2026
		}
		if start > 0 && start < minYear {
			minYear = start
		}
		if end > maxYear {
			maxYear = end
		}
	}
	if minYear == 9999 || maxYear <= minYear {
		return 3
	}
	years := float32(maxYear-minYear) + 0.5
	if years < 1 {
		years = 1
	}
	if years > 20 {
		years = 20
	}
	return years
}

func parseYear(s string) int {
	if s == "" {
		return 0
	}
	n := 0
	for _, c := range s {
		if c >= '0' && c <= '9' {
			n = n*10 + int(c-'0')
		}
	}
	return n
}

func joinExperienceText(doc CVDocument) string {
	var b strings.Builder
	for _, exp := range doc.Experience {
		b.WriteString(exp.Title)
		b.WriteString(" ")
		b.WriteString(exp.Period)
		b.WriteString(" ")
		b.WriteString(exp.Content)
		b.WriteString(" ")
	}
	return b.String()
}

func joinProjectsText(doc CVDocument) string {
	var b strings.Builder
	for _, p := range doc.Projects {
		b.WriteString(p.Title)
		b.WriteString(" ")
		b.WriteString(p.Period)
		b.WriteString(" ")
		b.WriteString(p.Content)
		b.WriteString(" ")
	}
	return b.String()
}

func splitHeadlineRole(headline string) string {
	_, role := splitHeadline(headline)
	return role
}
