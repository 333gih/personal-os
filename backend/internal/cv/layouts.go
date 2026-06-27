package cv

func ListLayouts() []CVLayoutProfile {
	return []CVLayoutProfile{
		{
			ID:          "two_column_one_page_v5",
			Label:       "Two column — 1 page (v5)",
			Description: "32/68 split: summary, skills, achievements left; experience & projects right. Fits one A4 page.",
			Constraints: DefaultConstraints(),
		},
	}
}

func DefaultConstraints() CVConstraints {
	return CVConstraints{MaxPages: 1, MaxExperience: 4, MaxProjects: 8}
}

func LayoutConstraints(layoutID string) CVConstraints {
	for _, l := range ListLayouts() {
		if l.ID == layoutID {
			return l.Constraints
		}
	}
	return DefaultConstraints()
}
