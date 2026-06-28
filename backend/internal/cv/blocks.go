package cv

import (
	"fmt"
	"strings"

	"github.com/google/uuid"
)

func contactParts(c Contact) []string {
	var parts []string
	for _, p := range []string{c.Email, c.Phone, c.Location, c.LinkedIn, c.GitHub} {
		p = strings.TrimSpace(p)
		if p != "" {
			parts = append(parts, p)
		}
	}
	return parts
}

func DocumentToBlocks(doc CVDocument) []CVBlock {
	var blocks []CVBlock
	order := 0
	add := func(b CVBlock) {
		b.Order = order
		order++
		blocks = append(blocks, b)
	}

	if doc.Summary != "" || doc.Headline != "" {
		content := doc.Summary
		if doc.Headline != "" && content != "" && !strings.Contains(content, doc.Headline) {
			content = doc.Headline + "\n" + content
		} else if content == "" {
			content = doc.Headline
		}
		add(CVBlock{ID: "summary", Type: "summary", Enabled: true, Content: content})
	}
	if parts := contactParts(doc.Contact); len(parts) > 0 {
		add(CVBlock{
			ID: "contact", Type: "contact", Enabled: true,
			Content:   formatContactDisplay(doc.Contact),
			Overrides: contactOverrides(doc.Contact),
		})
	}
	if len(doc.SkillGroups) > 0 {
		overrides := (*CVBlockOverrides)(nil)
		if len(doc.PrimaryStack) > 0 {
			overrides = &CVBlockOverrides{SkillItems: append([]string(nil), doc.PrimaryStack...)}
		}
		add(CVBlock{ID: "skills", Type: "skills", Enabled: true, SkillGroups: doc.SkillGroups, Overrides: overrides})
	}
	for i, a := range doc.Achievements {
		add(CVBlock{
			ID: fmt.Sprintf("achievement-%d", i), Type: "achievements", Enabled: true,
			Content: a.Content,
		})
	}
	for i, e := range doc.Education {
		content := e.School
		if e.Degree != "" {
			content += " · " + e.Degree
		}
		if e.Period != "" {
			content += " (" + e.Period + ")"
		}
		if e.Content != "" {
			content += "\n" + e.Content
		}
		add(CVBlock{
			ID: fmt.Sprintf("education-%d", i), Type: "education", Enabled: true, Content: content,
		})
	}
	for i, c := range doc.Certificates {
		add(CVBlock{
			ID: fmt.Sprintf("cert-%d", i), Type: "certificates", Enabled: true,
			Content: c.Title + " · " + c.Issuer,
		})
	}
	for _, exp := range doc.Experience {
		id := exp.ID
		if id == "" {
			id = uuid.NewString()
		}
		content := exp.Content
		add(CVBlock{
			ID: id, Type: "experience", Enabled: true, SourceEntityID: exp.ID,
			Content: content,
			Overrides: &CVBlockOverrides{
				Title: exp.Title, Company: exp.Company, Period: exp.Period,
			},
		})
	}
	for _, proj := range doc.Projects {
		id := proj.ID
		if id == "" {
			id = uuid.NewString()
		}
		content := proj.Content
		stack, cleaned := extractHighlightStack(content)
		add(CVBlock{
			ID: id, Type: "project", Enabled: true, SourceEntityID: proj.ID,
			Content: cleaned,
			Overrides: &CVBlockOverrides{
				Title: proj.Title, Company: proj.Company, Period: proj.Period,
				HighlightStack: stack,
			},
		})
	}
	return blocks
}

func BlocksToDocument(blocks []CVBlock) CVDocument {
	doc := CVDocument{Variant: "template"}
	for _, b := range blocks {
		if !b.Enabled {
			continue
		}
		switch b.Type {
		case "summary":
			headline, summary := splitSummaryBlock(blockText(b))
			if headline != "" {
				doc.Headline = headline
			}
			if summary != "" {
				doc.Summary = summary
			} else if headline != "" && doc.Summary == "" {
				doc.Summary = headline
			}
		case "contact":
			c := contactFromOverrides(b.Overrides)
			if strings.TrimSpace(c.Email+c.Phone+c.LinkedIn+c.GitHub) == "" {
				c = parseContactContent(blockText(b))
			}
			doc.Contact = mergeContact(doc.Contact, c)
		case "skills":
			if len(b.SkillGroups) > 0 {
				doc.SkillGroups = b.SkillGroups
			}
		case "achievements":
			doc.Achievements = append(doc.Achievements, AchievementItem{Content: blockText(b)})
		case "education":
			doc.Education = append(doc.Education, EducationItem{School: blockText(b)})
		case "certificates":
			doc.Certificates = append(doc.Certificates, CertificateItem{Title: blockText(b)})
		case "experience":
			doc.Experience = append(doc.Experience, blockToBullet(b))
		case "project":
			doc.Projects = append(doc.Projects, blockToBullet(b))
		}
	}
	NormalizeDocument(&doc)
	return doc
}

func blockText(b CVBlock) string {
	if strings.TrimSpace(b.Content) != "" {
		return strings.TrimSpace(b.Content)
	}
	return strings.TrimSpace(b.PendingRaw)
}

func blockToBullet(b CVBlock) BulletItem {
	item := BulletItem{
		ID:      b.SourceEntityID,
		Content: blockText(b),
		Section: b.Type,
	}
	if b.Overrides != nil {
		item.Title = b.Overrides.Title
		item.Company = b.Overrides.Company
		item.Period = b.Overrides.Period
		if len(b.Overrides.HighlightStack) > 0 {
			stack := strings.Join(b.Overrides.HighlightStack, ", ")
			if item.Content != "" {
				item.Content = stack + "\n" + item.Content
			} else {
				item.Content = stack
			}
		} else if len(b.Overrides.SkillItems) > 0 {
			stack := strings.Join(b.Overrides.SkillItems, ", ")
			if item.Content != "" {
				item.Content = "Skills: " + stack + "\n" + item.Content
			} else {
				item.Content = "Skills: " + stack
			}
		}
	}
	return item
}

func ApplySkillOverrides(doc *CVDocument, blocks []CVBlock) {
	for _, b := range blocks {
		if !b.Enabled || b.Type != "skills" || b.Overrides == nil {
			continue
		}
		if len(b.Overrides.SkillItems) == 0 {
			continue
		}
		cat := "Custom"
		if len(b.SkillGroups) > 0 {
			doc.SkillGroups = append(doc.SkillGroups, SkillGroup{Category: cat, Items: b.Overrides.SkillItems})
		} else {
			found := false
			for i := range doc.SkillGroups {
				if doc.SkillGroups[i].Category == cat {
					doc.SkillGroups[i].Items = append(doc.SkillGroups[i].Items, b.Overrides.SkillItems...)
					found = true
					break
				}
			}
			if !found {
				doc.SkillGroups = append(doc.SkillGroups, SkillGroup{Category: cat, Items: b.Overrides.SkillItems})
			}
		}
	}
	NormalizeDocument(doc)
}
