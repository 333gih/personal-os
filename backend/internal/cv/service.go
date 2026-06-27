package cv

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/storage"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

const idealDocumentID = "a000000a-0001-4001-8001-000000000001"

type Service struct {
	db      *gorm.DB
	ai      *ai.Service
	storage *storage.Service
}

func NewService(db *gorm.DB, aiSvc *ai.Service, storageSvc *storage.Service) *Service {
	return &Service{db: db, ai: aiSvc, storage: storageSvc}
}

func (s *Service) Get(userID uuid.UUID) (*AssembledCV, error) {
	if err := s.EnsureSystemCVSetup(userID); err == nil {
		if tpl, err := s.GetDefaultTemplate(userID); err == nil && tpl != nil && len(tpl.Blocks) > 0 {
			doc := BlocksToDocument(tpl.Blocks)
			ApplySkillOverrides(&doc, tpl.Blocks)
			NormalizeDocument(&doc)
			return &AssembledCV{
				DocumentID: tpl.ID,
				Document:   doc,
				Source:     "template",
			}, nil
		}
	}
	doc, err := s.loadDocument(userID)
	if err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	}
	if doc != nil {
		cvDoc := metadataToDocument(doc)
		NormalizeDocument(&cvDoc)
		return &AssembledCV{
			DocumentID: doc.ID.String(),
			Document:   cvDoc,
			Source:     "ideal",
		}, nil
	}
	assembled, err := s.assembleFromEntries(userID)
	if err != nil {
		return nil, err
	}
	NormalizeDocument(&assembled)
	return &AssembledCV{Document: assembled, Source: "assembled"}, nil
}

func (s *Service) Save(userID uuid.UUID, doc CVDocument) (*AssembledCV, error) {
	if tpl, err := s.GetDefaultTemplate(userID); err == nil && tpl != nil {
		tplID, _ := uuid.Parse(tpl.ID)
		tpl.Blocks = DocumentToBlocks(doc)
		saved, err := s.SaveTemplate(userID, tplID, *tpl, false)
		if err != nil {
			return nil, err
		}
		outDoc := BlocksToDocument(saved.Blocks)
		NormalizeDocument(&outDoc)
		return &AssembledCV{DocumentID: saved.ID, Document: outDoc, Source: "template"}, nil
	}
	doc.Variant = "ideal"
	NormalizeDocument(&doc)

	existing, err := s.loadDocument(userID)
	if err != nil && err != gorm.ErrRecordNotFound {
		return nil, err
	}

	if existing != nil {
		existing.Title = headlineTitle(doc)
		existing.Content = doc.Summary
		existing.Metadata = documentToMetadata(doc)
		if err := entityWrites(s.db).Save(existing).Error; err != nil {
			return nil, err
		}
		return &AssembledCV{DocumentID: existing.ID.String(), Document: doc, Source: "ideal"}, nil
	}

	fixedID, _ := uuid.Parse(idealDocumentID)
	ent := models.Entity{
		ID:       fixedID,
		UserID:   userID,
		Type:     models.TypeWorkCVDocument,
		Title:    headlineTitle(doc),
		Content:  doc.Summary,
		Tags:     datatypes.JSON(`["cv","ideal"]`),
		Source:   "cv_system",
		Metadata: documentToMetadata(doc),
		Status:   "active",
		Domain:   models.DomainWork,
	}
	if err := entityWrites(s.db).Create(&ent).Error; err != nil {
		return nil, err
	}
	return &AssembledCV{DocumentID: ent.ID.String(), Document: doc, Source: "ideal"}, nil
}

func (s *Service) Refine(userID uuid.UUID, req RefineRequest) (*RefineResponse, error) {
	if !s.ai.Configured() {
		return nil, fmt.Errorf("AI not configured — set OPENROUTER_API_KEY")
	}
	system := `You are a professional CV coach for Nguyen Khoa Minh Phuc (Software Engineer, HCMC).
Help refine resume text: clear, ATS-friendly, impact-focused bullets. Keep facts truthful.
Respond with JSON only: {"reply":"conversational feedback","refined_content":"optional improved text if user asked to rewrite"}`
	prompt := fmt.Sprintf("Section: %s\nCurrent content:\n%s\n\nUser request: %s",
		req.Section, req.Content, req.Instruction)
	raw, err := s.ai.ChatJSON(userID, "cv/refine", system, prompt)
	if err != nil {
		return nil, err
	}
	var out RefineResponse
	if err := json.Unmarshal([]byte(raw), &out); err != nil {
		out = RefineResponse{Reply: raw, RefinedContent: raw}
	}
	out.Section = req.Section
	return &out, nil
}

// MergeSkills appends deduplicated skill labels to the user's CV document.
func (s *Service) MergeSkills(userID uuid.UUID, skills []string) ([]string, error) {
	cv, err := s.Get(userID)
	if err != nil {
		return nil, err
	}
	doc := cv.Document
	NormalizeDocument(&doc)
	seen := map[string]bool{}
	for _, sk := range AllSkills(doc) {
		seen[strings.ToLower(strings.TrimSpace(sk))] = true
	}
	var added []string
	for _, sk := range skills {
		label := strings.TrimSpace(sk)
		if label == "" {
			continue
		}
		key := strings.ToLower(label)
		if seen[key] {
			continue
		}
		seen[key] = true
		added = append(added, label)
	}
	if len(added) == 0 {
		return nil, nil
	}
	if len(doc.SkillGroups) == 0 {
		doc.SkillGroups = []SkillGroup{{Category: "Skills", Items: added}}
	} else {
		doc.SkillGroups[0].Items = append(doc.SkillGroups[0].Items, added...)
	}
	doc.Skills = AllSkills(doc)
	if _, err := s.Save(userID, doc); err != nil {
		return nil, err
	}
	return added, nil
}

func (s *Service) ExportHTML(userID uuid.UUID) (string, error) {
	cv, err := s.Get(userID)
	if err != nil {
		return "", err
	}
	return renderHTML(cv.Document), nil
}

func (s *Service) ExportPDF(userID uuid.UUID) ([]byte, string, error) {
	cv, err := s.Get(userID)
	if err != nil {
		return nil, "", err
	}
	pdf, err := renderPDF(cv.Document)
	if err != nil {
		return nil, "", err
	}
	name := safeFilename(cv.Document.Headline) + ".pdf"
	return pdf, name, nil
}

func (s *Service) SharePDF(userID uuid.UUID) (*ShareResponse, error) {
	if s.storage == nil || !s.storage.Enabled() {
		return nil, storage.ErrStorageNotConfigured
	}
	data, filename, err := s.ExportPDF(userID)
	if err != nil {
		return nil, err
	}
	url, err := s.storage.UploadBytes(userID, "cv/"+filename, "application/pdf", data)
	if err != nil {
		return nil, err
	}
	return &ShareResponse{
		URL:       url,
		ExpiresIn: "24h",
		Filename:  filename,
	}, nil
}

func (s *Service) loadDocument(userID uuid.UUID) (*models.Entity, error) {
	var ent models.Entity
	err := s.db.Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeWorkCVDocument, "active").
		Order("updated_at DESC").
		First(&ent).Error
	return &ent, err
}

func (s *Service) assembleFromEntries(userID uuid.UUID) (CVDocument, error) {
	var entries []models.Entity
	if err := s.db.Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeWorkCVEntry, "active").
		Order("created_at ASC").
		Find(&entries).Error; err != nil {
		return CVDocument{}, err
	}

	doc := CVDocument{
		Variant:         "assembled",
		Headline:        "Software Engineer — AEM, Spring Boot, NestJS",
		Summary:         "Enterprise AEM/Spring Boot engineer with NestJS backend lead experience. Delivers migration pipelines, global search, and IoT platforms.",
		Contact:         Contact{Location: "Ho Chi Minh City, Vietnam"},
		SkillGroups:     defaultSkillGroups(),
		PrimaryStack:    []string{"Java", "Spring Boot", "AEM"},
		YearsExperience: 3.5,
	}
	doc.Skills = AllSkills(doc)

	for _, e := range entries {
		meta := map[string]any(e.Metadata)
		status, _ := meta["cv_status"].(string)
		if status != "in_cv" {
			continue
		}
		section, _ := meta["cv_section"].(string)
		item := BulletItem{
			ID:      e.ID.String(),
			Title:   strings.TrimPrefix(strings.TrimPrefix(e.Title, "CV: "), "Add to CV: "),
			Content: e.Content,
		}
		if company, ok := meta["company"].(string); ok {
			item.Company = company
		}
		if period, ok := meta["period"].(string); ok {
			item.Period = period
		}
		item.Section = section
		switch section {
		case "experience":
			doc.Experience = append(doc.Experience, item)
		case "projects":
			doc.Projects = append(doc.Projects, item)
		default:
			if strings.Contains(strings.ToLower(e.Title), "cv:") {
				doc.Experience = append(doc.Experience, item)
			} else {
				doc.Projects = append(doc.Projects, item)
			}
		}
	}
	return doc, nil
}

func metadataToDocument(ent *models.Entity) CVDocument {
	doc := CVDocument{Variant: "ideal", Summary: ent.Content}
	raw, _ := json.Marshal(ent.Metadata)
	_ = json.Unmarshal(raw, &doc)
	if doc.Headline == "" {
		doc.Headline = ent.Title
	}
	if doc.Summary == "" {
		doc.Summary = ent.Content
	}
	doc.UpdatedAt = ent.UpdatedAt.Format(time.RFC3339)
	return doc
}

func documentToMetadata(doc CVDocument) datatypes.JSONMap {
	raw, _ := json.Marshal(doc)
	var m map[string]any
	_ = json.Unmarshal(raw, &m)
	return m
}

func headlineTitle(doc CVDocument) string {
	if doc.Headline != "" {
		return "CV — " + doc.Headline
	}
	return "CV — Ideal Resume"
}

func safeFilename(s string) string {
	s = strings.ToLower(strings.TrimSpace(s))
	if s == "" {
		return "resume"
	}
	var b strings.Builder
	for _, r := range s {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' {
			b.WriteRune(r)
		} else if r == ' ' {
			b.WriteRune('-')
		}
	}
	out := b.String()
	if out == "" {
		return "resume"
	}
	return out
}
