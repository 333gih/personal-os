package cv

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

// entityWrites omits pgvector embedding on insert/update — empty [] is invalid for vector(1536).
func entityWrites(db *gorm.DB) *gorm.DB {
	return db.Omit("embedding")
}

func (s *Service) EnsureTemplatesMigrated(userID uuid.UUID) error {
	var count int64
	s.db.Model(&models.Entity{}).
		Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeWorkCVTemplate, "active").
		Count(&count)
	if count > 0 {
		return nil
	}
	docEnt, err := s.loadDocument(userID)
	if err != nil && err != gorm.ErrRecordNotFound {
		return err
	}
	var blocks []CVBlock
	layoutID := "two_column_one_page_v5"
	name := systemDefaultName
	if docEnt != nil {
		cvDoc := metadataToDocument(docEnt)
		NormalizeDocument(&cvDoc)
		blocks = DocumentToBlocks(cvDoc)
		if v, ok := docEnt.Metadata["layout_id"].(string); ok && v != "" {
			layoutID = v
		}
	} else {
		assembled, err := s.assembleFromEntries(userID)
		if err != nil {
			return err
		}
		blocks = DocumentToBlocks(assembled)
	}
	tpl := CVTemplate{
		Name:        name,
		LayoutID:    layoutID,
		IsDefault:   true,
		IsSystem:    true,
		Constraints: LayoutConstraints(layoutID),
		Blocks:      blocks,
	}
	_, err = s.createTemplateEntity(userID, tpl)
	return err
}

func (s *Service) ListTemplates(userID uuid.UUID) ([]CVTemplate, error) {
	if err := s.EnsureSystemCVSetup(userID); err != nil {
		return nil, err
	}
	var ents []models.Entity
	if err := s.db.Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeWorkCVTemplate, "active").
		Order("created_at ASC").Find(&ents).Error; err != nil {
		return nil, err
	}
	out := make([]CVTemplate, 0, len(ents))
	for _, e := range ents {
		out = append(out, entityToTemplate(&e))
	}
	sort.SliceStable(out, func(i, j int) bool {
		if out[i].IsSystem != out[j].IsSystem {
			return out[i].IsSystem
		}
		if out[i].IsDefault != out[j].IsDefault {
			return out[i].IsDefault
		}
		return out[i].Name < out[j].Name
	})
	return out, nil
}

func (s *Service) GetTemplate(userID, templateID uuid.UUID) (*CVTemplate, error) {
	if err := s.EnsureSystemCVSetup(userID); err != nil {
		return nil, err
	}
	ent, err := s.loadTemplateEntity(userID, templateID)
	if err != nil {
		return nil, err
	}
	tpl := entityToTemplate(ent)
	return &tpl, nil
}

func (s *Service) GetDefaultTemplate(userID uuid.UUID) (*CVTemplate, error) {
	if err := s.EnsureSystemCVSetup(userID); err != nil {
		return nil, err
	}
	var ent models.Entity
	err := s.db.Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeWorkCVTemplate, "active").
		Where("metadata->>'is_default' = 'true'").
		Order("updated_at DESC").First(&ent).Error
	if err == gorm.ErrRecordNotFound {
		err = s.db.Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeWorkCVTemplate, "active").
			Order("created_at ASC").First(&ent).Error
	}
	if err != nil {
		return nil, err
	}
	tpl := entityToTemplate(&ent)
	return &tpl, nil
}

func (s *Service) CreateTemplate(userID uuid.UUID, req CreateTemplateRequest) (*CVTemplate, error) {
	layoutID := req.LayoutID
	if layoutID == "" {
		layoutID = "two_column_one_page_v5"
	}
	tpl := CVTemplate{
		Name:        req.Name,
		LayoutID:    layoutID,
		IsDefault:   false,
		IsSystem:    false,
		Constraints: LayoutConstraints(layoutID),
		Blocks:      []CVBlock{},
	}
	if req.CloneID != "" {
		cloneID, err := uuid.Parse(req.CloneID)
		if err != nil {
			return nil, fmt.Errorf("invalid clone_id")
		}
		src, err := s.GetTemplate(userID, cloneID)
		if err != nil {
			return nil, err
		}
		tpl.Blocks = src.Blocks
		tpl.LayoutID = src.LayoutID
		tpl.Constraints = src.Constraints
	}
	ent, err := s.createTemplateEntity(userID, tpl)
	if err != nil {
		return nil, err
	}
	out := entityToTemplate(ent)
	return &out, nil
}

func (s *Service) SaveTemplate(userID, templateID uuid.UUID, tpl CVTemplate, force bool) (*CVTemplate, error) {
	ent, err := s.loadTemplateEntity(userID, templateID)
	if err != nil {
		return nil, err
	}
	existing := entityToTemplate(ent)
	if existing.IsSystem {
		forked, forkID, err := s.forkSystemTemplateIfNeeded(userID, &existing)
		if err != nil {
			return nil, err
		}
		tpl.ID = forked.ID
		tpl.IsSystem = false
		tpl.IsDefault = false
		if tpl.Name == existing.Name || tpl.Name == systemDefaultName || tpl.Name == systemRecommendedName || legacySystemName(tpl.Name) {
			tpl.Name = forked.Name
		}
		templateID = forkID
		ent, err = s.loadTemplateEntity(userID, templateID)
		if err != nil {
			return nil, err
		}
	}
	meta := map[string]any(ent.Metadata)
	if isDefault, _ := meta["is_default"].(bool); tpl.IsDefault && !isDefault {
		s.db.Model(&models.Entity{}).
			Where("user_id = ? AND type = ?", userID, models.TypeWorkCVTemplate).
			Update("metadata", gorm.Expr("metadata - 'is_default'"))
	}
	if !force {
		result, err := s.ValidateTemplate(userID, templateID, &tpl)
		if err != nil {
			return nil, err
		}
		if !result.Valid {
			return nil, fmt.Errorf("CV exceeds layout limits: %s", strings.Join(result.Overflows, "; "))
		}
	}
	ent.Title = "CV Template — " + tpl.Name
	ent.Metadata = templateToMetadata(tpl)
	if err := entityWrites(s.db).Save(ent).Error; err != nil {
		return nil, err
	}
	out := entityToTemplate(ent)
	return &out, nil
}

func (s *Service) DeleteTemplate(userID, templateID uuid.UUID) error {
	ent, err := s.loadTemplateEntity(userID, templateID)
	if err != nil {
		return err
	}
	meta := map[string]any(ent.Metadata)
	if isDefault, _ := meta["is_default"].(bool); isDefault {
		return fmt.Errorf("cannot delete default template")
	}
	if isSystem, _ := meta["is_system"].(bool); isSystem {
		return fmt.Errorf("cannot delete system template")
	}
	ent.Status = "archived"
	return entityWrites(s.db).Save(ent).Error
}

func (s *Service) ValidateTemplate(userID, templateID uuid.UUID, tplOverride *CVTemplate) (*ValidateResult, error) {
	var tpl CVTemplate
	if tplOverride != nil {
		tpl = *tplOverride
	} else {
		loaded, err := s.GetTemplate(userID, templateID)
		if err != nil {
			return nil, err
		}
		tpl = *loaded
	}
	doc := BlocksToDocument(tpl.Blocks)
	ApplySkillOverrides(&doc, tpl.Blocks)
	NormalizeDocument(&doc)
	if doc.Headline == "" {
		doc.Headline = tpl.Name
	}
	pdf, err := renderPDF(doc)
	if err != nil {
		return nil, err
	}
	pages := pdfPageCount(pdf)
	maxPages := tpl.Constraints.MaxPages
	if maxPages <= 0 {
		maxPages = 1
	}
	result := &ValidateResult{
		PageCount: pages,
		MaxPages:  maxPages,
		Valid:     pages <= maxPages,
	}
	if !result.Valid {
		result.Overflows = append(result.Overflows, fmt.Sprintf("PDF is %d pages (max %d)", pages, maxPages))
		expCount := len(doc.Experience)
		projCount := len(doc.Projects)
		if expCount > tpl.Constraints.MaxExperience && tpl.Constraints.MaxExperience > 0 {
			result.Overflows = append(result.Overflows, fmt.Sprintf("experience items: %d (max %d)", expCount, tpl.Constraints.MaxExperience))
			result.Suggestions = append(result.Suggestions, "Disable or shorten experience blocks")
		}
		if projCount > tpl.Constraints.MaxProjects && tpl.Constraints.MaxProjects > 0 {
			result.Overflows = append(result.Overflows, fmt.Sprintf("project items: %d (max %d)", projCount, tpl.Constraints.MaxProjects))
			result.Suggestions = append(result.Suggestions, "Disable or remove project blocks")
		}
	}
	return result, nil
}

func (s *Service) RefineBlock(userID uuid.UUID, req RefineBlockRequest) (*RefineResponse, error) {
	instruction := req.Instruction
	if strings.TrimSpace(instruction) == "" {
		instruction = "Professional tone, ATS-friendly, fix grammar and spelling, keep facts truthful"
	}
	return s.Refine(userID, RefineRequest{
		Instruction: instruction,
		Section:     "block",
		Content:     req.Content,
	})
}

func (s *Service) AddBlockFromEntity(userID, templateID uuid.UUID, req AddBlockFromEntityRequest) (*CVTemplate, error) {
	entID, err := uuid.Parse(req.EntityID)
	if err != nil {
		return nil, fmt.Errorf("invalid entity_id")
	}
	var workEnt models.Entity
	if err := s.db.Where("id = ? AND user_id = ? AND status = ?", entID, userID, "active").First(&workEnt).Error; err != nil {
		return nil, err
	}
	tpl, err := s.GetTemplate(userID, templateID)
	if err != nil {
		return nil, err
	}
	if tpl.IsSystem {
		forked, forkID, err := s.forkSystemTemplateIfNeeded(userID, tpl)
		if err != nil {
			return nil, err
		}
		tpl = forked
		templateID = forkID
	}
	blockType := req.BlockType
	if blockType == "" {
		blockType = inferBlockType(workEnt.Type)
	}
	overrides := req.Overrides
	if overrides == nil {
		overrides = &CVBlockOverrides{}
	}
	if overrides.Title == "" {
		overrides.Title = workEnt.Title
	}
	meta := map[string]any(workEnt.Metadata)
	if overrides.Company == "" {
		if c, ok := meta["company"].(string); ok {
			overrides.Company = c
		}
	}
	content := workEnt.Content
	stack, cleaned := extractHighlightStack(content)
	if len(overrides.HighlightStack) == 0 && len(stack) > 0 {
		overrides.HighlightStack = stack
		content = cleaned
	}
	block := CVBlock{
		ID:             uuid.NewString(),
		Type:           blockType,
		Enabled:        true,
		SourceEntityID: workEnt.ID.String(),
		Content:        content,
		Overrides:      overrides,
		Order:          len(tpl.Blocks),
	}
	tpl.Blocks = append(tpl.Blocks, block)
	saved, err := s.SaveTemplate(userID, templateID, *tpl, false)
	if err != nil && strings.Contains(err.Error(), "layout limits") {
		saved, err = s.SaveTemplate(userID, templateID, *tpl, true)
	}
	return saved, err
}

func inferBlockType(entityType string) string {
	switch {
	case strings.Contains(entityType, "project"):
		return "project"
	case strings.Contains(entityType, "role"), strings.Contains(entityType, "employer"):
		return "experience"
	default:
		return "project"
	}
}

func (s *Service) ExportPDFTemplate(userID, templateID uuid.UUID) ([]byte, string, error) {
	tpl, err := s.GetTemplate(userID, templateID)
	if err != nil {
		return nil, "", err
	}
	doc := BlocksToDocument(tpl.Blocks)
	ApplySkillOverrides(&doc, tpl.Blocks)
	NormalizeDocument(&doc)
	if doc.Headline == "" {
		doc.Headline = tpl.Name
	}
	pdf, err := renderPDF(doc)
	if err != nil {
		return nil, "", err
	}
	return pdf, safeFilename(doc.Headline) + ".pdf", nil
}

func (s *Service) createTemplateEntity(userID uuid.UUID, tpl CVTemplate) (*models.Entity, error) {
	ent := models.Entity{
		UserID:   userID,
		Type:     models.TypeWorkCVTemplate,
		Title:    "CV Template — " + tpl.Name,
		Content:  tpl.Name,
		Tags:     datatypes.JSON(`["cv","template"]`),
		Source:   "cv_system",
		Metadata: templateToMetadata(tpl),
		Status:   "active",
		Domain:   models.DomainWork,
	}
	if err := entityWrites(s.db).Create(&ent).Error; err != nil {
		return nil, err
	}
	return &ent, nil
}

func (s *Service) loadTemplateEntity(userID, templateID uuid.UUID) (*models.Entity, error) {
	var ent models.Entity
	err := s.db.Where("id = ? AND user_id = ? AND type = ? AND status = ?", templateID, userID, models.TypeWorkCVTemplate, "active").
		First(&ent).Error
	return &ent, err
}

func entityToTemplate(ent *models.Entity) CVTemplate {
	tpl := CVTemplate{
		ID:        ent.ID.String(),
		Name:      ent.Content,
		UpdatedAt: ent.UpdatedAt.Format(time.RFC3339),
	}
	raw, _ := json.Marshal(ent.Metadata)
	var meta struct {
		LayoutID    string        `json:"layout_id"`
		IsDefault   bool          `json:"is_default"`
		IsSystem    bool          `json:"is_system"`
		Constraints CVConstraints `json:"constraints"`
		Blocks      []CVBlock     `json:"blocks"`
		Name        string        `json:"name"`
	}
	_ = json.Unmarshal(raw, &meta)
	if meta.Name != "" {
		tpl.Name = meta.Name
	} else if strings.HasPrefix(ent.Title, "CV Template — ") {
		tpl.Name = strings.TrimPrefix(ent.Title, "CV Template — ")
	}
	tpl.LayoutID = meta.LayoutID
	if tpl.LayoutID == "" {
		tpl.LayoutID = "two_column_one_page_v5"
	}
	tpl.IsDefault = meta.IsDefault
	tpl.IsSystem = meta.IsSystem
	if tpl.IsDefault && (tpl.Name == systemDefaultName || tpl.Name == legacyDefaultName) {
		tpl.IsSystem = true
	}
	if tpl.Name == systemRecommendedName || tpl.Name == legacyRecommendedName {
		tpl.IsSystem = true
	}
	tpl.Constraints = meta.Constraints
	if tpl.Constraints.MaxPages == 0 {
		tpl.Constraints = LayoutConstraints(tpl.LayoutID)
	}
	tpl.Blocks = meta.Blocks
	return tpl
}

func templateToMetadata(tpl CVTemplate) datatypes.JSONMap {
	m := map[string]any{
		"layout_id":   tpl.LayoutID,
		"is_default":  tpl.IsDefault,
		"is_system":   tpl.IsSystem,
		"name":        tpl.Name,
		"constraints": tpl.Constraints,
		"blocks":      tpl.Blocks,
	}
	return m
}
