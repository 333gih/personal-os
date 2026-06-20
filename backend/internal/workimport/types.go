package workimport

import "github.com/personal-os/backend/internal/models"

type ArchitectureLayer struct {
	Layer string   `json:"layer"`
	Nodes []string `json:"nodes"`
}

type TechnologyImport struct {
	Name     string   `json:"name"`
	Content  string   `json:"content"`
	Category string   `json:"category"`
	Level    string   `json:"level"`
	Tags     []string `json:"tags"`
}

type FeatureImport struct {
	Title   string `json:"title"`
	Content string `json:"content"`
}

type NormalizedImport struct {
	Project struct {
		Title              string              `json:"title"`
		Company            string              `json:"company"`
		Summary            string              `json:"summary"`
		Status             string              `json:"status"`
		Role               string              `json:"role"`
		Stack              []string            `json:"stack"`
		Tags               []string            `json:"tags"`
		ArchitectureLayers []ArchitectureLayer `json:"architecture_layers"`
	} `json:"project"`
	DesignDoc struct {
		Title   string `json:"title"`
		Content string `json:"content"`
	} `json:"design_doc"`
	Technologies []TechnologyImport `json:"technologies"`
	Features     []FeatureImport      `json:"features"`
	CVSkills     []string             `json:"cv_skills"`
}

type ImportInput struct {
	TitleHint   string
	CompanyHint string
	Markdown    string
	ImageData   []byte
	ImageMIME   string
}

type ImportResult struct {
	ProjectID      string          `json:"project_id"`
	DesignDocID    string          `json:"design_doc_id,omitempty"`
	TechnologyIDs  []string        `json:"technology_ids"`
	FeatureIDs     []string        `json:"feature_ids"`
	DesignImageURL string          `json:"design_image_url,omitempty"`
	CVSkillsAdded  []string        `json:"cv_skills_added"`
	Project        models.Entity   `json:"project"`
	DesignDoc      *models.Entity  `json:"design_doc,omitempty"`
	Technologies   []models.Entity `json:"technologies,omitempty"`
}
