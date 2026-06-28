package cv

import "strings"

func contactOverrides(c Contact) *CVBlockOverrides {
	if strings.TrimSpace(c.Email+c.Phone+c.Location+c.LinkedIn+c.GitHub) == "" {
		return nil
	}
	return &CVBlockOverrides{
		Email:    strings.TrimSpace(c.Email),
		Phone:    strings.TrimSpace(c.Phone),
		Location: strings.TrimSpace(c.Location),
		LinkedIn: strings.TrimSpace(c.LinkedIn),
		GitHub:   strings.TrimSpace(c.GitHub),
	}
}

func contactFromOverrides(o *CVBlockOverrides) Contact {
	if o == nil {
		return Contact{}
	}
	return Contact{
		Email:    strings.TrimSpace(o.Email),
		Phone:    strings.TrimSpace(o.Phone),
		Location: strings.TrimSpace(o.Location),
		LinkedIn: strings.TrimSpace(o.LinkedIn),
		GitHub:   strings.TrimSpace(o.GitHub),
	}
}

func formatContactDisplay(c Contact) string {
	return strings.Join(contactParts(c), " · ")
}

func splitSummaryBlock(text string) (headline, summary string) {
	text = strings.TrimSpace(text)
	if text == "" {
		return "", ""
	}
	if i := strings.Index(text, "\n"); i >= 0 {
		return strings.TrimSpace(text[:i]), strings.TrimSpace(text[i+1:])
	}
	for _, sep := range []string{" — ", " – ", " - "} {
		if strings.Contains(text, sep) {
			return text, ""
		}
	}
	return "", text
}

func mergeContact(base, patch Contact) Contact {
	out := base
	if patch.Email != "" {
		out.Email = patch.Email
	}
	if patch.Phone != "" {
		out.Phone = patch.Phone
	}
	if patch.Location != "" {
		out.Location = patch.Location
	}
	if patch.LinkedIn != "" {
		out.LinkedIn = patch.LinkedIn
	}
	if patch.GitHub != "" {
		out.GitHub = patch.GitHub
	}
	return out
}

func parseContactContent(content string) Contact {
	_ = content
	return Contact{}
}

func profileOutdated(doc, canonical CVDocument) bool {
	if !strings.Contains(doc.Headline, "Nguyen Khoa Minh Phuc") {
		return true
	}
	want := canonical.Contact
	got := doc.Contact
	return got.Email != want.Email || got.GitHub != want.GitHub || got.LinkedIn != want.LinkedIn || got.Phone != want.Phone
}
