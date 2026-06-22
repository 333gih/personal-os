package cv

import "strings"

func projectsByCompany(projects []BulletItem) map[string][]BulletItem {
	out := map[string][]BulletItem{}
	for _, p := range projects {
		key := strings.TrimSpace(p.Company)
		if key == "" {
			key = "_ungrouped"
		}
		out[key] = append(out[key], p)
	}
	return out
}

func companyKey(company string) string {
	return strings.TrimSpace(company)
}

// atsKeywordLine flattens skills for ATS parsers and keyword matching (visible on CV).
func atsKeywordLine(doc CVDocument) string {
	skills := AllSkills(doc)
	if len(skills) == 0 {
		return ""
	}
	return strings.Join(skills, " · ")
}

// atsRoleKeywords repeats primary stack + role title for scanner-friendly density on page 1.
func atsRoleKeywords(doc CVDocument) string {
	_, role := splitHeadline(doc.Headline)
	parts := filterNonEmpty(append([]string{role}, doc.PrimaryStack...))
	if len(parts) == 0 {
		return ""
	}
	return strings.Join(parts, " · ")
}
