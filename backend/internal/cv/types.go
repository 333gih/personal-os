package cv

type Contact struct {
	Email    string `json:"email"`
	Phone    string `json:"phone"`
	Location string `json:"location"`
	LinkedIn string `json:"linkedin,omitempty"`
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
	Variant   string       `json:"variant"`
	Headline  string       `json:"headline"`
	Summary   string       `json:"summary"`
	Contact   Contact      `json:"contact"`
	Skills    []string     `json:"skills"`
	Experience []BulletItem `json:"experience"`
	Projects  []BulletItem `json:"projects"`
	PhotoURL  string       `json:"photo_url,omitempty"`
	UpdatedAt string       `json:"updated_at,omitempty"`
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
