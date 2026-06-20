package workimport

import (
	"encoding/json"
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/cv"
	"github.com/personal-os/backend/internal/embedding"
	"github.com/personal-os/backend/internal/entity"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/storage"
	"gorm.io/gorm"
)

const importSystemPrompt = `You normalize system design inputs (architecture diagrams, markdown notes) into Personal OS work domain data.
Extract project metadata, layered architecture, technologies/skills, and key features.
Respond with valid JSON only — no markdown fences, no commentary outside JSON.

Schema:
{
  "project": {
    "title": "string",
    "company": "string",
    "summary": "2-4 sentence project overview",
    "status": "active|completed|planned",
    "role": "engineer role if inferable",
    "stack": ["tech1","tech2"],
    "tags": ["lowercase","tags"],
    "architecture_layers": [{"layer":"Layer name","nodes":["Component A","Service B"]}]
  },
  "design_doc": {
    "title": "Architecture doc title",
    "content": "Markdown-friendly narrative of the system design"
  },
  "technologies": [
    {"name":"Spring Boot","content":"how it is used","category":"backend|frontend|cloud|database|search|messaging|platform|other","level":"beginner|intermediate|advanced","tags":["spring-boot"]}
  ],
  "features": [{"title":"Feature name","content":"what it does"}],
  "cv_skills": ["short skill labels for CV skills line"]
}

Rules:
- architecture_layers: group diagram boxes/services into 3-6 logical layers top-to-bottom or client-to-data.
- technologies: dedupe similar names; include every major stack item visible or mentioned.
- cv_skills: 3-12 concise skill names (e.g. "Spring Boot", "AEM", "PostgreSQL").
- If company/role unknown, use empty string; status defaults to active.`

type Service struct {
	db      *gorm.DB
	ai      *ai.Service
	storage *storage.Service
	entity  *entity.Service
	cv      *cv.Service
}

func NewService(db *gorm.DB, aiSvc *ai.Service, storageSvc *storage.Service, embedSvc *embedding.Service, cvSvc *cv.Service) *Service {
	return &Service{
		db:      db,
		ai:      aiSvc,
		storage: storageSvc,
		entity:  entity.NewService(db, aiSvc, embedSvc),
		cv:      cvSvc,
	}
}

func (s *Service) Import(userID uuid.UUID, input ImportInput) (*ImportResult, error) {
	markdown := strings.TrimSpace(input.Markdown)
	if markdown == "" && len(input.ImageData) == 0 {
		return nil, fmt.Errorf("provide markdown notes and/or a system design image")
	}
	if !s.ai.Configured() {
		return nil, fmt.Errorf("AI not configured — set OPENROUTER_API_KEY")
	}

	normalized, err := s.analyze(userID, input)
	if err != nil {
		return nil, err
	}

	designImageURL := ""
	designImages := []string{}
	if len(input.ImageData) > 0 {
		url, err := s.uploadDiagram(userID, input.ImageData, input.ImageMIME)
		if err == nil && url != "" {
			designImageURL = url
			designImages = append(designImages, url)
		}
	}

	projectMeta := map[string]any{
		"company":              firstNonEmpty(normalized.Project.Company, input.CompanyHint),
		"status":               defaultStatus(normalized.Project.Status),
		"has_design_system":    len(normalized.Project.ArchitectureLayers) > 0 || len(designImages) > 0,
		"architecture_layers":  normalized.Project.ArchitectureLayers,
		"stack":                normalized.Project.Stack,
	}
	if normalized.Project.Role != "" {
		projectMeta["role"] = normalized.Project.Role
	}
	if len(designImages) > 0 {
		projectMeta["design_images"] = designImages
	}

	projectTitle := firstNonEmpty(normalized.Project.Title, input.TitleHint, "Imported project")
	projectTags := normalized.Project.Tags
	if projectTags == nil {
		projectTags = []string{"imported", "architecture"}
	}

	projectEnt, err := s.entity.Create(userID, entity.CreateInput{
		Type:    models.TypeWorkProject,
		Title:   projectTitle,
		Content: normalized.Project.Summary,
		Tags:    projectTags,
		Source:  "work_import",
		Metadata: projectMeta,
	})
	if err != nil {
		return nil, fmt.Errorf("create project: %w", err)
	}

	result := &ImportResult{
		ProjectID:      projectEnt.ID.String(),
		DesignImageURL: designImageURL,
		Project:        *projectEnt,
	}

	if docTitle := strings.TrimSpace(normalized.DesignDoc.Title); docTitle != "" || strings.TrimSpace(normalized.DesignDoc.Content) != "" {
		docMeta := map[string]any{
			"project_id":        projectEnt.ID.String(),
			"doc_type":          "architecture",
			"has_design_system": true,
			"architecture_layers": normalized.Project.ArchitectureLayers,
		}
		if designImageURL != "" {
			docMeta["image"] = designImageURL
		}
		docEnt, err := s.entity.Create(userID, entity.CreateInput{
			Type:    models.TypeWorkDesignDoc,
			Title:   firstNonEmpty(docTitle, projectTitle+" — Architecture"),
			Content: normalized.DesignDoc.Content,
			Tags:    append([]string{"architecture", "imported"}, projectTags...),
			Source:  "work_import",
			Metadata: docMeta,
		})
		if err != nil {
			return nil, fmt.Errorf("create design doc: %w", err)
		}
		result.DesignDocID = docEnt.ID.String()
		result.DesignDoc = docEnt
		s.linkRelation(userID, docEnt.ID, projectEnt.ID, "documents")
	}

	for _, feat := range normalized.Features {
		title := strings.TrimSpace(feat.Title)
		if title == "" {
			continue
		}
		featEnt, err := s.entity.Create(userID, entity.CreateInput{
			Type:    models.TypeWorkFeature,
			Title:   title,
			Content: feat.Content,
			Tags:    []string{"imported"},
			Source:  "work_import",
			Metadata: map[string]any{
				"project_id": projectEnt.ID.String(),
			},
		})
		if err != nil {
			continue
		}
		result.FeatureIDs = append(result.FeatureIDs, featEnt.ID.String())
		s.linkRelation(userID, featEnt.ID, projectEnt.ID, "part_of")
	}

	for _, tech := range normalized.Technologies {
		name := strings.TrimSpace(tech.Name)
		if name == "" {
			continue
		}
		techEnt, created, err := s.findOrCreateTechnology(userID, tech)
		if err != nil || techEnt == nil {
			continue
		}
		result.TechnologyIDs = append(result.TechnologyIDs, techEnt.ID.String())
		if created {
			result.Technologies = append(result.Technologies, *techEnt)
		}
		s.linkRelation(userID, techEnt.ID, projectEnt.ID, "used_in")
	}

	skills := normalized.CVSkills
	for _, t := range normalized.Technologies {
		skills = append(skills, t.Name)
	}
	if s.cv != nil && len(skills) > 0 {
		added, err := s.cv.MergeSkills(userID, skills)
		if err == nil {
			result.CVSkillsAdded = added
		}
	}

	return result, nil
}

func (s *Service) analyze(userID uuid.UUID, input ImportInput) (*NormalizedImport, error) {
	var b strings.Builder
	b.WriteString("Normalize this into Personal OS work project data.\n")
	if input.TitleHint != "" {
		b.WriteString("Project title hint: " + input.TitleHint + "\n")
	}
	if input.CompanyHint != "" {
		b.WriteString("Company hint: " + input.CompanyHint + "\n")
	}
	if strings.TrimSpace(input.Markdown) != "" {
		b.WriteString("\n--- Markdown / notes ---\n")
		b.WriteString(input.Markdown)
		b.WriteString("\n")
	}
	if len(input.ImageData) > 0 && strings.TrimSpace(input.Markdown) == "" {
		b.WriteString("\nAnalyze the attached system design diagram and extract architecture layers, stack, and features.\n")
	}

	var raw string
	var err error
	if len(input.ImageData) > 0 {
		mime := input.ImageMIME
		if mime == "" {
			mime = "image/png"
		}
		raw, err = s.ai.ChatVisionJSON(userID, "work/import", importSystemPrompt, b.String(), mime, input.ImageData)
	} else {
		raw, err = s.ai.ChatJSON(userID, "work/import", importSystemPrompt, b.String())
	}
	if err != nil {
		return nil, err
	}

	var out NormalizedImport
	if err := parseJSONResponse(raw, &out); err != nil {
		return nil, fmt.Errorf("parse AI response: %w", err)
	}
	if strings.TrimSpace(out.Project.Title) == "" && input.TitleHint != "" {
		out.Project.Title = input.TitleHint
	}
	return &out, nil
}

func (s *Service) uploadDiagram(userID uuid.UUID, data []byte, mime string) (string, error) {
	if s.storage == nil || !s.storage.Enabled() {
		return "", nil
	}
	ext := ".png"
	switch mime {
	case "image/jpeg", "image/jpg":
		ext = ".jpg"
	case "image/webp":
		ext = ".webp"
	case "image/svg+xml":
		ext = ".svg"
	}
	key := fmt.Sprintf("work/design/%s-%d%s", uuid.New().String()[:8], time.Now().Unix(), ext)
	return s.storage.UploadBytes(userID, key, mime, data)
}

func (s *Service) findOrCreateTechnology(userID uuid.UUID, tech TechnologyImport) (*models.Entity, bool, error) {
	name := strings.TrimSpace(tech.Name)
	var existing models.Entity
	err := s.db.Where("user_id = ? AND type = ? AND lower(title) = lower(?)", userID, models.TypeTechnology, name).
		First(&existing).Error
	if err == nil {
		return &existing, false, nil
	}
	if err != gorm.ErrRecordNotFound {
		return nil, false, err
	}

	tags := tech.Tags
	if tags == nil {
		tags = []string{}
	}
	meta := map[string]any{
		"category": defaultCategory(tech.Category),
		"level":    defaultLevel(tech.Level),
	}
	ent, err := s.entity.Create(userID, entity.CreateInput{
		Type:    models.TypeTechnology,
		Title:   name,
		Content: tech.Content,
		Tags:    tags,
		Source:  "work_import",
		Metadata: meta,
	})
	if err != nil {
		return nil, false, err
	}
	return ent, true, nil
}

func (s *Service) linkRelation(userID, sourceID, targetID uuid.UUID, relationType string) {
	rel := models.Relationship{
		UserID:         userID,
		SourceEntityID: sourceID,
		TargetEntityID: targetID,
		RelationType:   relationType,
	}
	_ = s.db.Create(&rel).Error
}

func parseJSONResponse(raw string, dest any) error {
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

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return strings.TrimSpace(v)
		}
	}
	return ""
}

func defaultStatus(s string) string {
	switch strings.ToLower(strings.TrimSpace(s)) {
	case "completed", "planned", "active":
		return strings.ToLower(strings.TrimSpace(s))
	default:
		return "active"
	}
}

func defaultCategory(c string) string {
	c = strings.ToLower(strings.TrimSpace(c))
	if c == "" {
		return "other"
	}
	return c
}

func defaultLevel(l string) string {
	switch strings.ToLower(strings.TrimSpace(l)) {
	case "beginner", "intermediate", "advanced":
		return strings.ToLower(strings.TrimSpace(l))
	default:
		return "intermediate"
	}
}

func detectMIME(filename string, headerMIME string) string {
	if headerMIME != "" && strings.HasPrefix(headerMIME, "image/") {
		return headerMIME
	}
	switch strings.ToLower(filepath.Ext(filename)) {
	case ".jpg", ".jpeg":
		return "image/jpeg"
	case ".webp":
		return "image/webp"
	case ".svg":
		return "image/svg+xml"
	default:
		return "image/png"
	}
}
