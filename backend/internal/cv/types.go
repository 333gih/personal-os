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
