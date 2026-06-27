package cv

type Contact struct {
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Location string `json:"location"`
	LinkedIn string `json:"linkedin,omitempty"`
	GitHub   string `json:"github,omitempty"`
}

type SkillGroup struct {
	Category string   `json:"category"`
	Items    []string `json:"items"`
}

type EducationItem struct {
	School  string `json:"school"`
	Degree  string `json:"degree,omitempty"`
	Period  string `json:"period,omitempty"`
	Content string `json:"content,omitempty"`
}

type CertificateItem struct {
	Title  string `json:"title"`
	Issuer string `json:"issuer,omitempty"`
	Period string `json:"period,omitempty"`
}

// AchievementItem is a short highlight bullet for the left column (PDF v5 layout).
type AchievementItem struct {
	Content string `json:"content"`
}

type BulletItem struct {
	ID      string `json:"id,omitempty"`
	Title   string `json:"title"`
	Content string `json:"content"`
	Company string `json:"company,omitempty"`
	Period  string `json:"period,omitempty"`
	Section string `json:"section,omitempty"`
}

type CVDocument struct {
	Variant         string            `json:"variant"`
	Headline        string            `json:"headline"`
	Summary         string            `json:"summary"`
	Contact         Contact           `json:"contact"`
	Skills          []string          `json:"skills"`
	SkillGroups     []SkillGroup      `json:"skill_groups,omitempty"`
	PrimaryStack    []string          `json:"primary_stack,omitempty"`
	YearsExperience float32           `json:"years_experience,omitempty"`
	Education       []EducationItem   `json:"education,omitempty"`
	Achievements    []AchievementItem `json:"achievements,omitempty"`
	Certificates    []CertificateItem `json:"certificates,omitempty"`
	Experience      []BulletItem      `json:"experience"`
	Projects        []BulletItem      `json:"projects"`
	PhotoURL        string            `json:"photo_url,omitempty"`
	UpdatedAt       string            `json:"updated_at,omitempty"`
}

type AssembledCV struct {
	DocumentID string     `json:"document_id,omitempty"`
	Document   CVDocument `json:"document"`
	Source     string     `json:"source"` // ideal | assembled | hybrid
}

type SaveRequest struct {
	Document CVDocument `json:"document" binding:"required"`
}

type RefineRequest struct {
	Instruction string `json:"instruction" binding:"required"`
	Section     string `json:"section"`
	Content     string `json:"content"`
}

type RefineResponse struct {
	Reply          string `json:"reply"`
	RefinedContent string `json:"refined_content,omitempty"`
	Section        string `json:"section,omitempty"`
}

type ShareResponse struct {
	URL       string `json:"url"`
	ExpiresIn string `json:"expires_in"`
	Filename  string `json:"filename"`
}

type SuggestedSkill struct {
	Category string `json:"category"`
	Skill    string `json:"skill"`
	Reason   string `json:"reason,omitempty"`
}

type SuggestSkillsResponse struct {
	PrimaryStack []string         `json:"primary_stack"`
	Suggestions  []SuggestedSkill `json:"suggestions"`
}

type AddSkillRequest struct {
	Category string `json:"category" binding:"required"`
	Skill    string `json:"skill" binding:"required"`
}

type AddSkillResponse struct {
	Added    []string   `json:"added"`
	Document CVDocument `json:"document"`
}

// --- Multi-CV templates ---

type CVBlockOverrides struct {
	Title          string   `json:"title,omitempty"`
	Company        string   `json:"company,omitempty"`
	Period         string   `json:"period,omitempty"`
	HighlightStack []string `json:"highlight_stack,omitempty"`
	SkillItems     []string `json:"skill_items,omitempty"`
}

type CVBlock struct {
	ID             string            `json:"id"`
	Type           string            `json:"type"` // summary|experience|project|skills|education|achievements|certificates|contact
	Order          int               `json:"order"`
	Enabled        bool              `json:"enabled"`
	SourceEntityID string            `json:"source_entity_id,omitempty"`
	Content        string            `json:"content,omitempty"`
	Overrides      *CVBlockOverrides `json:"overrides,omitempty"`
	AIRefinedAt    string            `json:"ai_refined_at,omitempty"`
	PendingRaw     string            `json:"pending_raw,omitempty"`
	// skills block payload
	SkillGroups []SkillGroup `json:"skill_groups,omitempty"`
	// structured items for education/certificates/achievements
	Items []map[string]any `json:"items,omitempty"`
}

type CVConstraints struct {
	MaxPages      int `json:"max_pages"`
	MaxExperience int `json:"max_experience"`
	MaxProjects   int `json:"max_projects"`
}

type CVTemplate struct {
	ID          string        `json:"id"`
	Name        string        `json:"name"`
	LayoutID    string        `json:"layout_id"`
	IsDefault   bool          `json:"is_default"`
	IsSystem    bool          `json:"is_system"`
	Constraints CVConstraints `json:"constraints"`
	Blocks      []CVBlock     `json:"blocks"`
	UpdatedAt   string        `json:"updated_at,omitempty"`
}

type CVLayoutProfile struct {
	ID          string        `json:"id"`
	Label       string        `json:"label"`
	Description string        `json:"description"`
	Constraints CVConstraints `json:"constraints"`
}

type ValidateResult struct {
	Valid      bool     `json:"valid"`
	PageCount  int      `json:"page_count"`
	MaxPages   int      `json:"max_pages"`
	Overflows  []string `json:"overflows,omitempty"`
	Suggestions []string `json:"suggestions,omitempty"`
}

type CreateTemplateRequest struct {
	Name     string `json:"name" binding:"required"`
	LayoutID string `json:"layout_id"`
	CloneID  string `json:"clone_id"`
}

type SaveTemplateRequest struct {
	Template CVTemplate `json:"template" binding:"required"`
	Force    bool       `json:"force"`
}

type RefineBlockRequest struct {
	Instruction string `json:"instruction"`
	Content     string `json:"content" binding:"required"`
}

type AddBlockFromEntityRequest struct {
	EntityID   string            `json:"entity_id" binding:"required"`
	BlockType  string            `json:"block_type" binding:"required"`
	Overrides  *CVBlockOverrides `json:"overrides,omitempty"`
}
