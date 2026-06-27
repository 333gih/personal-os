package cv

import (
	"bytes"
	"strings"

	"github.com/jung-kurt/gofpdf"
)

const (
	cvMarginL = 10.0
	cvMarginR = 10.0
	cvMarginT = 10.0
	cvMarginB = 10.0
	cvAccentR = 26
	cvAccentG = 54
	cvAccentB = 93

	cvFontName    = 15.5
	cvFontRole    = 9.5
	cvFontContact = 7.5
	cvFontSection = 7.8
	cvFontBody    = 7.5
	cvFontSmall   = 7.0
	cvFontBullet  = 7.3

	cvLineBody   = 3.4
	cvLineTight  = 3.2
	cvLineTitle  = 4.0
	cvSectionGap = 2.8
	cvBlockGap   = 2.0
)

func renderPDF(doc CVDocument) ([]byte, error) {
	NormalizeDocument(&doc)
	pdf, err := newCVPDF()
	if err != nil {
		return nil, err
	}

	pdf.AddPage()
	pdf.SetAutoPageBreak(false, 0)

	pageW, pageH := pdf.GetPageSize()
	contentW := pageW - cvMarginL - cvMarginR
	leftW := contentW * 0.32
	rightW := contentW - leftW - 5
	leftX := cvMarginL
	rightX := cvMarginL + leftW + 5

	name, role := splitHeadline(doc.Headline)
	setDejaVu(pdf, "B", cvFontName)
	pdf.SetTextColor(cvAccentR, cvAccentG, cvAccentB)
	pdf.SetXY(cvMarginL, cvMarginT)
	pdf.MultiCell(contentW, 6.5, strings.ToUpper(name), "", "L", false)

	if role != "" {
		setDejaVu(pdf, "", cvFontRole)
		pdf.SetTextColor(55, 65, 81)
		pdf.SetX(cvMarginL)
		pdf.MultiCell(contentW, 4.5, role, "", "L", false)
	}

	pdf.SetTextColor(0, 0, 0)
	pdf.Ln(1)
	renderPDFContact(pdf, contentW, doc.Contact)

	columnStartY := pdf.GetY() + 3
	resetPDFRightSpacing()
	resetPDFLeftSpacing()
	resetPDFCompressScale()

	leftEndY, rightEndY := pdfFitColumnsToPage(pdf, leftX, rightX, columnStartY, leftW, rightW, pageH, doc)

	pdf.SetPage(1)
	leftEndY, rightEndY = pdfBalanceColumns(pdf, leftX, rightX, columnStartY, leftW, rightW, leftEndY, rightEndY, pageH, doc)
	_ = leftEndY
	_ = rightEndY

	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func renderPDFLeftColumn(pdf *gofpdf.Fpdf, x, y, w float64, doc CVDocument) float64 {
	if doc.Summary != "" {
		y = pdfSection(pdf, x, y, w, "Summary", pdfLeftSectionGap(), func(y float64) float64 {
			setDejaVu(pdf, "", cvFontBody)
			return pdfMC(pdf, x, y, w, pdfLeftLineHeight(), strings.TrimSpace(doc.Summary))
		})
	}

	if len(doc.Education) > 0 {
		y = pdfSection(pdf, x, y, w, "Educations", pdfLeftSectionGap(), func(y float64) float64 {
			for _, e := range doc.Education {
				schoolLine := e.School
				if e.Period != "" {
					schoolLine += " (" + e.Period + ")"
				}
				setDejaVu(pdf, "B", cvFontBody)
				y = pdfMC(pdf, x, y, w, pdfLeftLineHeight(), schoolLine)
				if e.Content != "" {
					setDejaVu(pdf, "", cvFontSmall)
					y = pdfMC(pdf, x, y, w, pdfLeftLineHeight(), e.Content)
				}
				y += pdfLeftBlockGap()
			}
			return y
		})
	}

	if len(doc.SkillGroups) > 0 || len(doc.Skills) > 0 {
		y = pdfSection(pdf, x, y, w, "Skills", pdfLeftSectionGap(), func(y float64) float64 {
			if len(doc.SkillGroups) > 0 {
				for _, g := range doc.SkillGroups {
					if len(g.Items) == 0 {
						continue
					}
					setDejaVu(pdf, "B", cvFontBody)
					y = pdfMC(pdf, x, y, w, pdfLeftLineHeight(), g.Category+":")
					setDejaVu(pdf, "", cvFontSmall)
					y = pdfMC(pdf, x, y, w, pdfLeftLineHeight(), strings.Join(g.Items, ", "))
					y += pdfLeftBlockGap() * 0.5
				}
			} else {
				setDejaVu(pdf, "", cvFontBody)
				y = pdfMC(pdf, x, y, w, pdfLeftLineHeight(), formatSkillLine(doc.Skills))
			}
			return y
		})
	}

	if len(doc.Achievements) > 0 {
		y = pdfSection(pdf, x, y, w, "Achievements", pdfLeftSectionGap(), func(y float64) float64 {
			for _, a := range doc.Achievements {
				if strings.TrimSpace(a.Content) == "" {
					continue
				}
				setDejaVu(pdf, "", cvFontBullet)
				y = pdfMC(pdf, x+1.2, y, w-1.2, pdfLeftLineHeight(), "•  "+strings.TrimSpace(a.Content))
			}
			return y
		})
	}

	if len(doc.Certificates) > 0 {
		y = pdfSection(pdf, x, y, w, "Certificates", pdfLeftSectionGap(), func(y float64) float64 {
			for _, c := range doc.Certificates {
				line := c.Title
				if c.Issuer != "" {
					line += " — " + c.Issuer
				}
				setDejaVu(pdf, "", cvFontSmall)
				y = pdfMC(pdf, x, y, w, pdfLeftLineHeight(), line)
				if c.Period != "" {
					setDejaVu(pdf, "I", cvFontSmall)
					pdf.SetTextColor(90, 90, 90)
					y = pdfMC(pdf, x, y, w, pdfLeftLineHeight(), c.Period)
					pdf.SetTextColor(0, 0, 0)
				}
				y += pdfLeftBlockGap() * 0.5
			}
			return y
		})
	}

	return y
}

func renderPDFRightColumn(pdf *gofpdf.Fpdf, x, y, w float64, doc CVDocument) float64 {
	if len(doc.Experience) == 0 {
		return y
	}

	y = pdfSection(pdf, x, y, w, "Experiences", cvSectionGap, func(y float64) float64 {
		grouped := projectsByCompany(doc.Projects)
		for _, item := range doc.Experience {
			y = pdfRoleBlock(pdf, x, y, w, item, true)
			for _, p := range grouped[companyKey(item.Company)] {
				y = pdfRoleBlock(pdf, x, y, w, p, false)
			}
		}
		for _, p := range grouped["_ungrouped"] {
			y = pdfRoleBlock(pdf, x, y, w, p, false)
		}
		return y
	})

	return y
}

func renderPDFContact(pdf *gofpdf.Fpdf, contentW float64, c Contact) {
	parts := filterNonEmpty([]string{c.Email, c.Phone, c.Location, c.LinkedIn, c.GitHub})
	if len(parts) == 0 {
		return
	}
	setDejaVu(pdf, "", cvFontContact)
	pdf.SetTextColor(90, 100, 110)
	pdf.SetX(cvMarginL)
	pdf.MultiCell(contentW, 3.5, strings.Join(parts, "   ·   "), "", "L", false)
	pdf.SetTextColor(0, 0, 0)
}

func pdfSection(pdf *gofpdf.Fpdf, x, y, w float64, title string, sectionGap float64, body func(y float64) float64) float64 {
	setDejaVu(pdf, "B", cvFontSection)
	pdf.SetTextColor(17, 24, 39)
	pdf.SetXY(x, y)
	pdf.Cell(w, cvLineTitle, strings.ToUpper(title))

	lineY := y + cvLineTitle
	pdf.SetDrawColor(17, 24, 39)
	pdf.SetLineWidth(0.3)
	pdf.Line(x, lineY, x+w, lineY)

	bodyY := lineY + 2.2
	pdf.SetTextColor(0, 0, 0)
	endY := body(bodyY)
	return endY + sectionGap
}

func pdfRoleBlock(pdf *gofpdf.Fpdf, x, y, w float64, item BulletItem, showCompany bool) float64 {
	if showCompany && strings.TrimSpace(item.Company) != "" {
		setDejaVu(pdf, "B", cvFontBody)
		pdf.SetTextColor(17, 24, 39)
		y = pdfMC(pdf, x, y, w, cvLineBody, strings.ToUpper(strings.TrimSpace(item.Company)))
		pdf.SetTextColor(0, 0, 0)
	}

	title := strings.TrimSpace(item.Title)
	period := strings.TrimSpace(item.Period)
	if title != "" || period != "" {
		periodW := 34.0
		titleW := w - periodW
		if period == "" {
			titleW = w
		}
		setDejaVu(pdf, "B", cvFontBody)
		pdf.SetXY(x, y)
		pdf.Cell(titleW, cvLineBody, title)
		if period != "" {
			setDejaVu(pdf, "I", cvFontSmall)
			pdf.SetTextColor(100, 100, 100)
			pdf.CellFormat(periodW, cvLineBody, period, "", 0, "R", false, 0, "")
			pdf.SetTextColor(0, 0, 0)
		}
		y += cvLineBody + 0.5
	}

	for _, bullet := range splitBullets(item.Content) {
		setDejaVu(pdf, "", cvFontBullet)
		y = pdfMC(pdf, x+1.2, y, w-1.2, pdfRoleLineHeight(), "•  "+bullet)
	}
	return y + pdfRoleBlockGap()
}

// pdfMC writes wrapped text at (x,y) without triggering page breaks.
func pdfMC(pdf *gofpdf.Fpdf, x, y, w, lineH float64, text string) float64 {
	pdf.SetXY(x, y)
	pdf.MultiCell(w, lineH, text, "", "L", false)
	return pdf.GetY()
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

func pdfPageCount(data []byte) int {
	s := string(data)
	return strings.Count(s, "/Type /Page") - strings.Count(s, "/Type /Pages")
}
