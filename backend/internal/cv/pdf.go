package cv

import (
	"bytes"
	"strings"

	"github.com/jung-kurt/gofpdf"
)

const (
	cvMarginL = 12.0
	cvMarginR = 12.0
	cvMarginT = 12.0
	cvMarginB = 14.0
	cvAccentR = 26
	cvAccentG = 54
	cvAccentB = 93
)

func renderPDF(doc CVDocument) ([]byte, error) {
	NormalizeDocument(&doc)
	pdf, err := newCVPDF()
	if err != nil {
		return nil, err
	}

	pdf.AddPage()
	pageW, _ := pdf.GetPageSize()
	contentW := pageW - cvMarginL - cvMarginR
	leftW := contentW * 0.32
	rightW := contentW - leftW - 6
	leftX := cvMarginL
	rightX := cvMarginL + leftW + 6

	name, role := splitHeadline(doc.Headline)
	setDejaVu(pdf, "B", 18)
	pdf.SetTextColor(cvAccentR, cvAccentG, cvAccentB)
	pdf.MultiCell(contentW, 7.5, strings.ToUpper(name), "", "L", false)

	if role != "" {
		setDejaVu(pdf, "", 10.5)
		pdf.SetTextColor(55, 65, 81)
		pdf.Ln(1)
		pdf.MultiCell(contentW, 5, role, "", "L", false)
	}

	pdf.SetTextColor(0, 0, 0)
	pdf.Ln(2)
	renderPDFContact(pdf, contentW, doc.Contact)

	startY := pdf.GetY() + 4
	leftY := startY
	rightY := startY

	if doc.Summary != "" {
		leftY = pdfColumnSection(pdf, leftX, leftY, leftW, "Summary", func() float64 {
			setDejaVu(pdf, "", 8.5)
			pdf.SetX(leftX)
			pdf.MultiCell(leftW, 4.2, strings.TrimSpace(doc.Summary), "", "L", false)
			return pdf.GetY()
		})
	}

	if len(doc.SkillGroups) > 0 || len(doc.Skills) > 0 {
		leftY = pdfColumnSection(pdf, leftX, leftY, leftW, "Skills", func() float64 {
			setDejaVu(pdf, "", 8)
			if len(doc.SkillGroups) > 0 {
				for _, g := range doc.SkillGroups {
					if len(g.Items) == 0 {
						continue
					}
					pdf.SetX(leftX)
					setDejaVu(pdf, "B", 8)
					pdf.MultiCell(leftW, 4, g.Category+":", "", "L", false)
					setDejaVu(pdf, "", 8)
					pdf.SetX(leftX)
					pdf.MultiCell(leftW, 4, strings.Join(g.Items, ", "), "", "L", false)
					pdf.Ln(1)
				}
			} else {
				pdf.SetX(leftX)
				pdf.MultiCell(leftW, 4, formatSkillLine(doc.Skills), "", "L", false)
			}
			return pdf.GetY()
		})
	}

	if len(doc.Education) > 0 {
		leftY = pdfColumnSection(pdf, leftX, leftY, leftW, "Educations", func() float64 {
			setDejaVu(pdf, "", 8)
			for _, e := range doc.Education {
				pdf.SetX(leftX)
				setDejaVu(pdf, "B", 8)
				pdf.MultiCell(leftW, 4, e.School, "", "L", false)
				meta := filterNonEmpty([]string{e.Degree, e.Period})
				if len(meta) > 0 {
					setDejaVu(pdf, "I", 7.5)
					pdf.SetTextColor(90, 90, 90)
					pdf.SetX(leftX)
					pdf.MultiCell(leftW, 3.8, strings.Join(meta, " · "), "", "L", false)
					pdf.SetTextColor(0, 0, 0)
				}
				if e.Content != "" {
					setDejaVu(pdf, "", 8)
					pdf.SetX(leftX)
					pdf.MultiCell(leftW, 4, e.Content, "", "L", false)
				}
				pdf.Ln(1.5)
			}
			return pdf.GetY()
		})
	}

	if len(doc.Certificates) > 0 {
		leftY = pdfColumnSection(pdf, leftX, leftY, leftW, "Certificates", func() float64 {
			setDejaVu(pdf, "", 8)
			for _, c := range doc.Certificates {
				line := c.Title
				if c.Issuer != "" {
					line += " — " + c.Issuer
				}
				pdf.SetX(leftX)
				pdf.MultiCell(leftW, 4, line, "", "L", false)
				if c.Period != "" {
					setDejaVu(pdf, "I", 7.5)
					pdf.SetTextColor(90, 90, 90)
					pdf.SetX(leftX)
					pdf.MultiCell(leftW, 3.8, c.Period, "", "L", false)
					pdf.SetTextColor(0, 0, 0)
				}
				pdf.Ln(1)
			}
			return pdf.GetY()
		})
	}

	if len(doc.Experience) > 0 {
		rightY = pdfColumnSectionAt(pdf, rightX, rightY, rightW, "Experiences", func() float64 {
			y := pdf.GetY()
			for _, item := range doc.Experience {
				y = pdfRoleBlockAt(pdf, rightX, y, rightW, item, true)
			}
			return y
		})
	}

	if len(doc.Projects) > 0 {
		rightY = pdfColumnSectionAt(pdf, rightX, rightY, rightW, "Projects", func() float64 {
			y := pdf.GetY()
			for _, item := range doc.Projects {
				y = pdfRoleBlockAt(pdf, rightX, y, rightW, item, false)
			}
			return y
		})
	}

	_ = leftY
	_ = rightY

	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func renderPDFContact(pdf *gofpdf.Fpdf, contentW float64, c Contact) {
	parts := filterNonEmpty([]string{c.Email, c.Phone, c.Location, c.LinkedIn, c.GitHub})
	if len(parts) == 0 {
		return
	}
	setDejaVu(pdf, "", 8)
	pdf.SetTextColor(90, 100, 110)
	pdf.MultiCell(contentW, 4, strings.Join(parts, "   ·   "), "", "L", false)
	pdf.SetTextColor(0, 0, 0)
}

func pdfColumnSection(pdf *gofpdf.Fpdf, x, y, w float64, title string, body func() float64) float64 {
	return pdfColumnSectionAt(pdf, x, y, w, title, body)
}

func pdfColumnSectionAt(pdf *gofpdf.Fpdf, x, y, w float64, title string, body func() float64) float64 {
	pdf.SetXY(x, y)
	setDejaVu(pdf, "B", 8.5)
	pdf.SetTextColor(17, 24, 39)
	pdf.Cell(w, 4.5, strings.ToUpper(title))
	pdf.Ln(5)
	pdf.SetDrawColor(17, 24, 39)
	pdf.SetLineWidth(0.35)
	lineY := pdf.GetY()
	pdf.Line(x, lineY, x+w, lineY)
	pdf.Ln(3)
	pdf.SetTextColor(0, 0, 0)
	endY := body()
	if endY <= lineY {
		endY = pdf.GetY()
	}
	return endY + 4
}

func pdfRoleBlockAt(pdf *gofpdf.Fpdf, x, y, contentW float64, item BulletItem, showCompany bool) float64 {
	pdf.SetXY(x, y)
	if showCompany && strings.TrimSpace(item.Company) != "" {
		setDejaVu(pdf, "B", 8.5)
		pdf.SetTextColor(17, 24, 39)
		pdf.SetX(x)
		pdf.MultiCell(contentW, 4.2, strings.ToUpper(strings.TrimSpace(item.Company)), "", "L", false)
		pdf.SetTextColor(0, 0, 0)
	}

	title := strings.TrimSpace(item.Title)
	period := strings.TrimSpace(item.Period)
	if title != "" || period != "" {
		periodW := 36.0
		titleW := contentW - periodW
		if period == "" {
			titleW = contentW
		}
		setDejaVu(pdf, "B", 8.5)
		pdf.SetXY(x, pdf.GetY())
		pdf.Cell(titleW, 4.2, title)
		if period != "" {
			setDejaVu(pdf, "I", 7.5)
			pdf.SetTextColor(100, 100, 100)
			pdf.CellFormat(periodW, 4.2, period, "", 0, "R", false, 0, "")
			pdf.SetTextColor(0, 0, 0)
		}
		pdf.Ln(4.5)
	}

	for _, bullet := range splitBullets(item.Content) {
		setDejaVu(pdf, "", 8)
		pdf.SetX(x + 1.5)
		pdf.MultiCell(contentW-1.5, 4, "•  "+bullet, "", "L", false)
	}
	return pdf.GetY() + 2.5
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
