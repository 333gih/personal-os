package cv

import (
	"encoding/json"
	"fmt"
	"regexp"
	"sort"
	"strings"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

const (
	systemDefaultName       = "Professional CV (1 page)"
	systemRecommendedName   = "Stack-optimized CV"
	legacyDefaultName       = "Default (1-page)"
	legacyRecommendedName   = "AI Recommended"
	systemCVSeedRevision    = 2
)

var techLineRE = regexp.MustCompile(`(?i)(?:^|\n)\s*Tech:\s*(.+?)(?:\n|$)`)

func (s *Service) EnsureSystemCVSetup(userID uuid.UUID) error {
	return s.ensureSystemCVSetup(userID, false)
}

func (s *Service) ForceSyncSystemCVSetup(userID uuid.UUID) error {
	return s.ensureSystemCVSetup(userID, true)
}

func (s *Service) ensureSystemCVSetup(userID uuid.UUID, force bool) error {
	if err := s.EnsureTemplatesMigrated(userID); err != nil {
		return err
	}
	baseDoc, err := s.ensureIdealDocument(userID)
	if err != nil {
		return err
	}

	var templates []models.Entity
	if err := s.db.Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeWorkCVTemplate, "active").
		Order("created_at ASC").Find(&templates).Error; err != nil {
		return err
	}

	hasDefault := false
	hasRecommended := false
	for i := range templates {
		tpl := entityToTemplate(&templates[i])
		if tpl.Name == systemDefaultName || tpl.IsDefault {
			hasDefault = true
		}
		if tpl.Name == systemRecommendedName {
			hasRecommended = true
		}
		if isSystemTemplate(tpl) {
			doc := baseDoc
			if tpl.Name == systemRecommendedName {
				doc = BuildRecommendedDocument(baseDoc)
			}
			if force || templateBlocksNeedSync(tpl.Blocks) || legacySystemName(tpl.Name) {
				if err := s.syncTemplateBlocks(userID, templates[i].ID, doc); err != nil {
					return err
				}
			}
			continue
		}
		if len(tpl.Blocks) == 0 {
			if err := s.syncTemplateBlocks(userID, templates[i].ID, baseDoc); err != nil {
				return err
			}
		}
	}

	if !hasDefault {
		tpl := CVTemplate{
			Name:        systemDefaultName,
			LayoutID:    "two_column_one_page_v5",
			IsDefault:   true,
			IsSystem:    true,
			Constraints: LayoutConstraints("two_column_one_page_v5"),
			Blocks:      DocumentToBlocks(baseDoc),
		}
		if _, err := s.createTemplateEntity(userID, tpl); err != nil {
			return err
		}
	}

	if !hasRecommended {
		recDoc := BuildRecommendedDocument(baseDoc)
		tpl := CVTemplate{
			Name:        systemRecommendedName,
			LayoutID:    "two_column_one_page_v5",
			IsDefault:   false,
			IsSystem:    true,
			Constraints: LayoutConstraints("two_column_one_page_v5"),
			Blocks:      DocumentToBlocks(recDoc),
		}
		if _, err := s.createTemplateEntity(userID, tpl); err != nil {
			return err
		}
	}

	return nil
}

func isSystemTemplate(tpl CVTemplate) bool {
	if tpl.IsSystem {
		return true
	}
	switch tpl.Name {
	case systemDefaultName, systemRecommendedName, legacyDefaultName, legacyRecommendedName:
		return true
	}
	return tpl.IsDefault && tpl.Name != ""
}

func legacySystemName(name string) bool {
	return name == legacyDefaultName || name == legacyRecommendedName
}

func normalizeSystemTemplateName(tpl *CVTemplate) {
	switch tpl.Name {
	case legacyDefaultName, systemDefaultName:
		tpl.Name = systemDefaultName
		tpl.IsDefault = true
		tpl.IsSystem = true
	case legacyRecommendedName, systemRecommendedName:
		if tpl.Name == legacyRecommendedName {
			tpl.Name = systemRecommendedName
		}
		tpl.IsSystem = true
	}
}

func templateBlocksNeedSync(blocks []CVBlock) bool {
	if len(blocks) == 0 {
		return true
	}
	hasExp, hasProj := false, false
	for _, b := range blocks {
		if !b.Enabled {
			continue
		}
		switch b.Type {
		case "experience":
			hasExp = true
		case "project":
			hasProj = true
		}
	}
	return !hasExp && !hasProj
}

func (s *Service) ensureIdealDocument(userID uuid.UUID) (CVDocument, error) {
	docEnt, err := s.loadDocument(userID)
	if err == gorm.ErrRecordNotFound {
		doc := CanonicalIdealCV()
		if upsertErr := s.upsertIdealDocument(userID, doc); upsertErr != nil {
			return CVDocument{}, upsertErr
		}
		return doc, nil
	}
	if err != nil {
		return CVDocument{}, err
	}
	doc := metadataToDocument(docEnt)
	NormalizeDocument(&doc)
	if documentIsSparse(doc) {
		doc = CanonicalIdealCV()
		if upsertErr := s.upsertIdealDocument(userID, doc); upsertErr != nil {
			return CVDocument{}, upsertErr
		}
		return doc, nil
	}
	canonical := CanonicalIdealCV()
	if profileOutdated(doc, canonical) {
		doc = canonical
		if upsertErr := s.upsertIdealDocument(userID, doc); upsertErr != nil {
			return CVDocument{}, upsertErr
		}
	}
	return doc, nil
}

func (s *Service) upsertIdealDocument(userID uuid.UUID, doc CVDocument) error {
	doc.Variant = "ideal"
	NormalizeDocument(&doc)
	existing, err := s.loadDocument(userID)
	if err != nil && err != gorm.ErrRecordNotFound {
		return err
	}
	if existing != nil {
		existing.Title = headlineTitle(doc)
		existing.Content = doc.Summary
		existing.Metadata = documentToMetadata(doc)
		return entityWrites(s.db).Save(existing).Error
	}
	fixedID, _ := uuid.Parse(idealDocumentID)
	ent := models.Entity{
		ID:       fixedID,
		UserID:   userID,
		Type:     models.TypeWorkCVDocument,
		Title:    headlineTitle(doc),
		Content:  doc.Summary,
		Tags:     datatypes.JSON(`["cv","ideal","transfer"]`),
		Source:   "cv_system",
		Metadata: documentToMetadata(doc),
		Status:   "active",
		Domain:   models.DomainWork,
	}
	return entityWrites(s.db).Create(&ent).Error
}

func (s *Service) syncTemplateBlocks(userID uuid.UUID, templateID uuid.UUID, doc CVDocument) error {
	ent, err := s.loadTemplateEntity(userID, templateID)
	if err != nil {
		return err
	}
	tpl := entityToTemplate(ent)
	tpl.Blocks = DocumentToBlocks(doc)
	normalizeSystemTemplateName(&tpl)
	if tpl.IsDefault && tpl.Name == systemDefaultName {
		tpl.IsSystem = true
	}
	if tpl.Name == systemRecommendedName {
		tpl.IsSystem = true
	}
	ent.Title = "CV Template — " + tpl.Name
	ent.Content = tpl.Name
	ent.Metadata = templateToMetadata(tpl)
	return entityWrites(s.db).Save(ent).Error
}

func (s *Service) loadIdealDocument(userID uuid.UUID) (CVDocument, bool) {
	doc, err := s.ensureIdealDocument(userID)
	if err != nil {
		return CVDocument{}, false
	}
	return doc, true
}

func (s *Service) backfillTemplateBlocks(userID uuid.UUID, templateID uuid.UUID, doc CVDocument) error {
	return s.syncTemplateBlocks(userID, templateID, doc)
}

// BuildRecommendedDocument reorders skills and projects for the user's primary stack (fast, no AI call).
func BuildRecommendedDocument(doc CVDocument) CVDocument {
	raw, _ := json.Marshal(doc)
	var out CVDocument
	_ = json.Unmarshal(raw, &out)
	NormalizeDocument(&out)
	profile := BuildStackProfile(out)

	out.Projects = sortProjectsByStack(out.Projects, profile.PrimaryStack)
	out.SkillGroups = prioritizeSkillGroups(out.SkillGroups, profile.PrimaryStack)

	if len(out.Experience) > 4 {
		out.Experience = out.Experience[:4]
	}
	maxProjects := 8
	if len(out.Projects) > maxProjects {
		out.Projects = out.Projects[:maxProjects]
	}

	if len(profile.PrimaryStack) > 0 {
		focus := strings.Join(profile.PrimaryStack, ", ")
		if !strings.Contains(strings.ToLower(out.Summary), strings.ToLower(profile.PrimaryStack[0])) {
			out.Summary = strings.TrimSpace(out.Summary + " Focus: " + focus + ".")
		}
	}
	return out
}

func sortProjectsByStack(projects []BulletItem, primaryStack []string) []BulletItem {
	if len(projects) <= 1 || len(primaryStack) == 0 {
		return projects
	}
	out := append([]BulletItem(nil), projects...)
	sort.SliceStable(out, func(i, j int) bool {
		return projectStackScore(out[i], primaryStack) > projectStackScore(out[j], primaryStack)
	})
	return out
}

func projectStackScore(item BulletItem, primaryStack []string) int {
	text := strings.ToLower(item.Title + " " + item.Content + " " + item.Company)
	score := 0
	for _, stack := range primaryStack {
		for _, part := range strings.FieldsFunc(strings.ToLower(stack), func(r rune) bool {
			return r == ',' || r == '/' || r == ' '
		}) {
			part = strings.TrimSpace(part)
			if len(part) < 2 {
				continue
			}
			if strings.Contains(text, part) {
				score += 3
			}
		}
	}
	return score
}

func prioritizeSkillGroups(groups []SkillGroup, primaryStack []string) []SkillGroup {
	if len(groups) <= 1 {
		return groups
	}
	focus := strings.ToLower(strings.Join(primaryStack, " "))
	out := append([]SkillGroup(nil), groups...)
	sort.SliceStable(out, func(i, j int) bool {
		return skillGroupScore(out[i], focus) > skillGroupScore(out[j], focus)
	})
	return out
}

func skillGroupScore(g SkillGroup, focus string) int {
	cat := strings.ToLower(g.Category)
	score := 0
	if strings.Contains(focus, "java") || strings.Contains(focus, "spring") {
		if strings.Contains(cat, "java") || strings.Contains(cat, "spring") || strings.Contains(cat, "enterprise") {
			score += 10
		}
	}
	if strings.Contains(focus, "aem") && strings.Contains(cat, "aem") {
		score += 10
	}
	for _, item := range g.Items {
		itemL := strings.ToLower(item)
		for _, token := range strings.Fields(focus) {
			if strings.Contains(itemL, token) {
				score += 2
			}
		}
	}
	return score
}

func extractHighlightStack(content string) ([]string, string) {
	m := techLineRE.FindStringSubmatch(content)
	if len(m) < 2 {
		return nil, content
	}
	parts := strings.Split(m[1], ",")
	var stack []string
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			stack = append(stack, p)
		}
	}
	cleaned := strings.TrimSpace(techLineRE.ReplaceAllString(content, ""))
	return stack, cleaned
}

func (s *Service) forkSystemTemplateIfNeeded(userID uuid.UUID, tpl *CVTemplate) (*CVTemplate, uuid.UUID, error) {
	if !tpl.IsSystem {
		id, err := uuid.Parse(tpl.ID)
		return tpl, id, err
	}
	name := nextUserTemplateName(s.db, userID, "My CV")
	fork := CVTemplate{
		Name:        name,
		LayoutID:    tpl.LayoutID,
		IsDefault:   false,
		IsSystem:    false,
		Constraints: tpl.Constraints,
		Blocks:      append([]CVBlock(nil), tpl.Blocks...),
	}
	ent, err := s.createTemplateEntity(userID, fork)
	if err != nil {
		return nil, uuid.Nil, err
	}
	out := entityToTemplate(ent)
	id, _ := uuid.Parse(out.ID)
	return &out, id, nil
}

func nextUserTemplateName(db *gorm.DB, userID uuid.UUID, base string) string {
	var ents []models.Entity
	_ = db.Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeWorkCVTemplate, "active").Find(&ents)
	prefix := base
	maxN := 0
	for _, e := range ents {
		name := entityToTemplate(&e).Name
		if name == prefix {
			if maxN < 1 {
				maxN = 1
			}
		}
		if strings.HasPrefix(name, prefix+" ") {
			var n int
			if _, err := fmt.Sscanf(name, prefix+" %d", &n); err == nil && n > maxN {
				maxN = n
			}
		}
	}
	if maxN == 0 {
		return prefix
	}
	return fmt.Sprintf("%s %d", prefix, maxN+1)
}
