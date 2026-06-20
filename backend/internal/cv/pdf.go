package cv

import (
	"bytes"
	"strings"

	"github.com/jung-kurt/gofpdf"
)

const (
	cvMarginL = 16.0
	cvMarginR = 16.0
	cvMarginT = 14.0
	cvMarginB = 16.0
	cvAccentR = 26
	cvAccentG = 54
	cvAccentB = 93
)

func renderPDF(doc CVDocument) ([]byte, error) {
	pdf, err := newCVPDF()
	if err != nil {
		return nil, err
	}

	pdf.AddPage()
	contentW, _ := pdf.GetPageSize()
	contentW -= cvMarginL + cvMarginR

	name, role := splitHeadline(doc.Headline)
	setDejaVu(pdf, "B", 20)
	pdf.SetTextColor(cvAccentR, cvAccentG, cvAccentB)
	pdf.MultiCell(contentW, 8.5, name, "", "L", false)

	if role != "" {
		setDejaVu(pdf, "", 11)
		pdf.SetTextColor(90, 90, 90)
		pdf.Ln(1)
		pdf.MultiCell(contentW, 5.5, role, "", "L", false)
	}

	pdf.SetTextColor(0, 0, 0)
	pdf.Ln(3)
	pdf.SetDrawColor(cvAccentR, cvAccentG, cvAccentB)
	pdf.SetLineWidth(0.55)
	y := pdf.GetY()
	pdf.Line(cvMarginL, y, cvMarginL+contentW, y)
	pdf.Ln(5)

	contactParts := filterNonEmpty([]string{
		doc.Contact.Email,
		doc.Contact.Phone,
		doc.Contact.Location,
		doc.Contact.LinkedIn,
	})
	if len(contactParts) > 0 {
		setDejaVu(pdf, "", 9.5)
		pdf.SetTextColor(70, 70, 70)
		pdf.MultiCell(contentW, 4.8, strings.Join(contactParts, "  ·  "), "", "L", false)
		pdf.SetTextColor(0, 0, 0)
		pdf.Ln(2)
	}

	if strings.TrimSpace(doc.Summary) != "" {
		pdfSection(pdf, "Summary")
		setDejaVu(pdf, "", 10)
		pdf.MultiCell(contentW, 5.2, strings.TrimSpace(doc.Summary), "", "L", false)
	}

	if len(doc.Skills) > 0 {
		pdfSection(pdf, "Skills")
		setDejaVu(pdf, "", 9.5)
		pdf.MultiCell(contentW, 5, formatSkillLine(doc.Skills), "", "L", false)
	}

	if len(doc.Experience) > 0 {
		pdfSection(pdf, "Experience")
		for _, item := range doc.Experience {
			pdfRoleBlock(pdf, contentW, item, true)
		}
	}

	if len(doc.Projects) > 0 {
		pdfSection(pdf, "Projects")
		for _, item := range doc.Projects {
			pdfRoleBlock(pdf, contentW, item, false)
		}
	}

	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func splitHeadline(headline string) (name, role string) {
	headline = strings.TrimSpace(headline)
	if headline == "" {
		return "Curriculum Vitae", ""
	}
	for _, sep := range []string{" — ", " – ", " - ", " | "} {
		if i := strings.Index(headline, sep); i > 0 {
			return strings.TrimSpace(headline[:i]), strings.TrimSpace(headline[i+len(sep):])
		}
	}
	return headline, ""
}

func formatSkillLine(skills []string) string {
	return strings.Join(filterNonEmpty(skills), "   ·   ")
}

func pdfSection(pdf *gofpdf.Fpdf, title string) {
	pdf.Ln(7)
	setDejaVu(pdf, "B", 9.5)
	pdf.SetTextColor(cvAccentR, cvAccentG, cvAccentB)
	pdf.Cell(0, 5, strings.ToUpper(title))
	pdf.Ln(6)
	pdf.SetDrawColor(210, 214, 220)
	pdf.SetLineWidth(0.2)
	x := cvMarginL
	w, _ := pdf.GetPageSize()
	w -= cvMarginL + cvMarginR
	y := pdf.GetY()
	pdf.Line(x, y, x+w, y)
	pdf.Ln(4)
	pdf.SetTextColor(0, 0, 0)
}

func pdfRoleBlock(pdf *gofpdf.Fpdf, contentW float64, item BulletItem, showCompany bool) {
	if showCompany && strings.TrimSpace(item.Company) != "" {
		setDejaVu(pdf, "B", 10.5)
		pdf.SetTextColor(cvAccentR, cvAccentG, cvAccentB)
		pdf.MultiCell(contentW, 5, strings.TrimSpace(item.Company), "", "L", false)
		pdf.SetTextColor(0, 0, 0)
	}

	title := strings.TrimSpace(item.Title)
	period := strings.TrimSpace(item.Period)
	if title != "" || period != "" {
		periodW := 42.0
		titleW := contentW - periodW
		if period == "" {
			titleW = contentW
		}
		setDejaVu(pdf, "B", 10)
		pdf.Cell(titleW, 5, title)
		if period != "" {
			setDejaVu(pdf, "I", 9)
			pdf.SetTextColor(100, 100, 100)
			pdf.CellFormat(periodW, 5, period, "", 0, "R", false, 0, "")
			pdf.SetTextColor(0, 0, 0)
		}
		pdf.Ln(5.5)
	}

	for _, bullet := range splitBullets(item.Content) {
		setDejaVu(pdf, "", 9.5)
		pdf.SetX(cvMarginL + 2)
		pdf.MultiCell(contentW-2, 4.9, "•  "+bullet, "", "L", false)
	}
	pdf.Ln(2.5)
}

func splitBullets(content string) []string {
	content = strings.TrimSpace(content)
	if content == "" {
		return nil
	}

	raw := strings.ReplaceAll(content, "\r\n", "\n")
	parts := strings.FieldsFunc(raw, func(r rune) bool {
		return r == '\n'
	})
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		part = strings.TrimPrefix(part, "•")
		part = strings.TrimPrefix(part, "-")
		part = strings.TrimSpace(part)
		if part != "" {
			out = append(out, part)
		}
	}
	if len(out) > 0 {
		return out
	}

	// Single paragraph — split long sentences for readability.
	sentences := strings.Split(content, ". ")
	for i, s := range sentences {
		s = strings.TrimSpace(s)
		if s == "" {
			continue
		}
		if i < len(sentences)-1 && !strings.HasSuffix(s, ".") {
			s += "."
		}
		out = append(out, s)
	}
	if len(out) == 0 {
		return []string{content}
	}
	return out
}
