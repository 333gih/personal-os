package cv

import (
	"strings"
	"testing"
)

func TestRenderPDF_UTF8Characters(t *testing.T) {
	doc := CVDocument{
		Headline: "Nguyen Khoa Minh Phuc — Software Engineer",
		Summary:  "Enterprise AEM/Spring Boot engineer.",
		Contact: Contact{
			Email:    "test@example.com",
			Location: "Ho Chi Minh City, Vietnam",
		},
		Skills: []string{"Java", "Spring Boot", "AEM"},
		Experience: []BulletItem{
			{
				Company: "FPT Software",
				Title:   "Software Engineer",
				Period:  "2025 — Present",
				Content: "FTP→XML→XSL→AEM workflow.\nSpring Boot 3 migration.",
			},
		},
	}

	data, err := renderPDF(doc)
	if err != nil {
		t.Fatalf("renderPDF: %v", err)
	}
	if len(data) < 1024 {
		t.Fatalf("pdf too small: %d bytes", len(data))
	}
	if !strings.HasPrefix(string(data[:5]), "%PDF-") {
		t.Fatalf("not a pdf header")
	}
}

func TestSplitHeadline(t *testing.T) {
	name, role := splitHeadline("Nguyen Khoa Minh Phuc — Software Engineer")
	if name != "Nguyen Khoa Minh Phuc" || role != "Software Engineer" {
		t.Fatalf("unexpected split: %q / %q", name, role)
	}
}

func TestSplitBullets(t *testing.T) {
	got := splitBullets("Line one\nLine two")
	if len(got) != 2 || got[0] != "Line one" || got[1] != "Line two" {
		t.Fatalf("unexpected bullets: %#v", got)
	}
}
