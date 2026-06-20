package cv

import (
	"bytes"
	"fmt"
	"strings"

	"github.com/jung-kurt/gofpdf"
)

func renderPDF(doc CVDocument) ([]byte, error) {
	pdf := gofpdf.New("P", "mm", "A4", "")
	pdf.SetMargins(18, 18, 18)
	pdf.AddPage()
	pdf.SetFont("Helvetica", "B", 18)
	pdf.MultiCell(0, 9, doc.Headline, "", "L", false)

	pdf.SetFont("Helvetica", "", 10)
	contact := strings.Join(filterNonEmpty([]string{doc.Contact.Email, doc.Contact.Phone, doc.Contact.Location}), "  ·  ")
	if contact != "" {
		pdf.Ln(2)
		pdf.SetTextColor(80, 80, 80)
		pdf.MultiCell(0, 5, contact, "", "L", false)
		pdf.SetTextColor(0, 0, 0)
	}

	if doc.Summary != "" {
		pdf.Ln(6)
		pdf.SetFont("Helvetica", "", 11)
		pdf.MultiCell(0, 5.5, doc.Summary, "", "L", false)
	}

	if len(doc.Skills) > 0 {
		pdfSection(pdf, "Skills")
		pdf.SetFont("Helvetica", "", 10)
		pdf.MultiCell(0, 5, strings.Join(doc.Skills, "  ·  "), "", "L", false)
	}

	if len(doc.Experience) > 0 {
		pdfSection(pdf, "Experience")
		for _, item := range doc.Experience {
			pdfBulletBlock(pdf, item)
		}
	}

	if len(doc.Projects) > 0 {
		pdfSection(pdf, "Projects")
		for _, item := range doc.Projects {
			pdfBulletBlock(pdf, item)
		}
	}

	var buf bytes.Buffer
	if err := pdf.Output(&buf); err != nil {
		return nil, err
	}
	return buf.Bytes(), nil
}

func pdfSection(pdf *gofpdf.Fpdf, title string) {
	pdf.Ln(8)
	pdf.SetFont("Helvetica", "B", 11)
	pdf.SetTextColor(40, 40, 40)
	pdf.Cell(0, 6, strings.ToUpper(title))
	pdf.Ln(7)
	pdf.SetDrawColor(200, 200, 200)
	pdf.Line(18, pdf.GetY(), 192, pdf.GetY())
	pdf.Ln(4)
	pdf.SetTextColor(0, 0, 0)
}

func pdfBulletBlock(pdf *gofpdf.Fpdf, item BulletItem) {
	title := item.Title
	if item.Company != "" {
		title = fmt.Sprintf("%s — %s", item.Company, item.Title)
	}
	pdf.SetFont("Helvetica", "B", 10)
	pdf.MultiCell(0, 5, "• "+title, "", "L", false)
	if item.Period != "" {
		pdf.SetFont("Helvetica", "I", 9)
		pdf.SetTextColor(100, 100, 100)
		pdf.MultiCell(0, 4.5, item.Period, "", "L", false)
		pdf.SetTextColor(0, 0, 0)
	}
	if item.Content != "" {
		pdf.SetFont("Helvetica", "", 10)
		pdf.MultiCell(0, 5, item.Content, "", "L", false)
	}
	pdf.Ln(2)
}
