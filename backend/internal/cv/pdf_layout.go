package cv

import (
	"strings"
)

const (
	cvColumnBottomPad = 4.0 // mm — small gap above page bottom
	cvLayoutMinScale  = 0.70
)

type layoutTrimLevel int

const (
	trimNone layoutTrimLevel = iota
	trimLight
	trimMedium
	trimHeavy
)

func prepareDocumentForPDF(doc CVDocument) CVDocument {
	out := doc
	NormalizeDocument(&out)
	if len(out.Experience) > 4 {
		out.Experience = append([]BulletItem(nil), out.Experience[:4]...)
	}
	if len(out.Projects) > 8 {
		out.Projects = append([]BulletItem(nil), out.Projects[:8]...)
	}
	return out
}

func layoutDocumentVariants(doc CVDocument) []CVDocument {
	base := prepareDocumentForPDF(doc)
	return []CVDocument{
		base,
		trimDocumentForLayout(base, trimLight),
		trimDocumentForLayout(base, trimMedium),
		trimDocumentForLayout(base, trimHeavy),
	}
}

func trimDocumentForLayout(doc CVDocument, level layoutTrimLevel) CVDocument {
	if level == trimNone {
		return doc
	}
	out := doc
	out.Summary = trimParagraph(doc.Summary, summaryLimit(level))
	out.Achievements = trimAchievements(doc.Achievements, achievementLimit(level))
	out.Education = trimEducation(doc.Education, level)
	out.SkillGroups = compactSkillGroups(doc.SkillGroups, skillCategoryLimit(level), skillItemsLimit(level))
	out.Certificates = trimCertificates(doc.Certificates, certLimit(level))
	out.Experience = trimBulletItems(doc.Experience, expBulletLimit(level), bulletCharLimit(level))
	out.Projects = trimBulletItems(doc.Projects, projBulletLimit(level), bulletCharLimit(level))
	return out
}

func summaryLimit(level layoutTrimLevel) int {
	switch level {
	case trimLight:
		return 520
	case trimMedium:
		return 420
	default:
		return 340
	}
}

func achievementLimit(level layoutTrimLevel) int {
	switch level {
	case trimLight:
		return 140
	case trimMedium:
		return 110
	default:
		return 90
	}
}

func skillCategoryLimit(level layoutTrimLevel) int {
	switch level {
	case trimLight:
		return 6
	case trimMedium:
		return 5
	default:
		return 4
	}
}

func skillItemsLimit(level layoutTrimLevel) int {
	switch level {
	case trimLight:
		return 8
	case trimMedium:
		return 6
	default:
		return 5
	}
}

func certLimit(level layoutTrimLevel) int {
	if level >= trimMedium {
		return 2
	}
	return 3
}

func expBulletLimit(level layoutTrimLevel) int {
	switch level {
	case trimLight:
		return 5
	case trimMedium:
		return 4
	default:
		return 3
	}
}

func projBulletLimit(level layoutTrimLevel) int {
	switch level {
	case trimLight:
		return 5
	case trimMedium:
		return 4
	default:
		return 3
	}
}

func bulletCharLimit(level layoutTrimLevel) int {
	switch level {
	case trimLight:
		return 260
	case trimMedium:
		return 210
	default:
		return 175
	}
}

func trimParagraph(s string, max int) string {
	s = strings.TrimSpace(s)
	if max <= 0 || len(s) <= max {
		return s
	}
	if max <= 3 {
		return s[:max]
	}
	return strings.TrimSpace(s[:max-1]) + "…"
}

func trimAchievements(items []AchievementItem, maxLen int) []AchievementItem {
	if len(items) == 0 {
		return items
	}
	out := make([]AchievementItem, 0, len(items))
	for _, a := range items {
		content := trimParagraph(strings.TrimSpace(a.Content), maxLen)
		if content == "" {
			continue
		}
		out = append(out, AchievementItem{Content: content})
	}
	return out
}

func trimEducation(items []EducationItem, level layoutTrimLevel) []EducationItem {
	if len(items) == 0 {
		return items
	}
	out := make([]EducationItem, 0, len(items))
	maxContent := 120
	if level >= trimMedium {
		maxContent = 90
	}
	for _, e := range items {
		e.Content = trimParagraph(e.Content, maxContent)
		out = append(out, e)
	}
	return out
}

func trimCertificates(items []CertificateItem, max int) []CertificateItem {
	if len(items) <= max {
		return items
	}
	return append([]CertificateItem(nil), items[:max]...)
}

func compactSkillGroups(groups []SkillGroup, maxCategories, maxItems int) []SkillGroup {
	if len(groups) == 0 {
		return groups
	}
	out := make([]SkillGroup, 0, len(groups))
	for _, g := range groups {
		if len(g.Items) == 0 {
			continue
		}
		items := g.Items
		if len(items) > maxItems {
			items = append([]string(nil), items[:maxItems]...)
		}
		out = append(out, SkillGroup{Category: g.Category, Items: items})
	}
	if len(out) <= maxCategories {
		return out
	}
	kept := append([]SkillGroup(nil), out[:maxCategories-1]...)
	var other []string
	for _, g := range out[maxCategories-1:] {
		other = append(other, g.Items...)
	}
	if len(other) > maxItems {
		other = other[:maxItems]
	}
	kept = append(kept, SkillGroup{Category: "Other", Items: other})
	return kept
}

func trimBulletItems(items []BulletItem, maxBullets, maxChars int) []BulletItem {
	if len(items) == 0 {
		return items
	}
	out := make([]BulletItem, 0, len(items))
	for _, item := range items {
		copy := item
		copy.Content = compressBulletContent(item.Content, maxBullets, maxChars)
		out = append(out, copy)
	}
	return out
}

func compressBulletContent(content string, maxLines, maxLineLen int) string {
	bullets := splitBullets(content)
	if maxLines > 0 && len(bullets) > maxLines {
		bullets = bullets[:maxLines]
	}
	for i, b := range bullets {
		bullets[i] = trimParagraph(b, maxLineLen)
	}
	return strings.Join(bullets, "\n")
}
