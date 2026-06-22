package cv

import (
	"fmt"
	"strings"

	"github.com/jung-kurt/gofpdf"
)

const cvColumnFillMinGap = 4.0 // mm — fill when shorter column trails by this much

func pdfColumnTargetY(pageH float64) float64 {
	return pageH - cvMarginB - 2
}

func pdfBalanceColumns(pdf *gofpdf.Fpdf, leftX, rightX, leftW, rightW, leftEndY, rightEndY, pageH float64, doc CVDocument) {
	targetY := pdfColumnTargetY(pageH)
	columnBottom := leftEndY
	if rightEndY > columnBottom {
		columnBottom = rightEndY
	}
	if columnBottom < targetY {
		columnBottom = targetY
	}

	if rightEndY < columnBottom-cvColumnFillMinGap {
		rightEndY = pdfFillRightColumn(pdf, rightX, rightEndY, columnBottom, rightW, doc)
	}
	if leftEndY < columnBottom-cvColumnFillMinGap {
		pdfFillLeftColumn(pdf, leftX, leftEndY, columnBottom, leftW, doc)
	}
	_ = rightEndY
}

func pdfFillRightColumn(pdf *gofpdf.Fpdf, x, y, targetY, w float64, doc CVDocument) float64 {
	if line := atsRoleKeywords(doc); line != "" && y < targetY-cvColumnFillMinGap {
		y = pdfSection(pdf, x, y, w, "Role & Stack", func(y float64) float64 {
			setDejaVu(pdf, "", cvFontSmall)
			return pdfMC(pdf, x, y, w, cvLineTight, line)
		})
	}
	if line := atsKeywordLine(doc); line != "" && y < targetY-cvColumnFillMinGap {
		y = pdfSection(pdf, x, y, w, "Core Technologies", func(y float64) float64 {
			setDejaVu(pdf, "", cvFontSmall)
			return pdfMC(pdf, x, y, w, cvLineTight, line)
		})
	}
	if y < targetY-cvColumnFillMinGap {
		y = pdfSection(pdf, x, y, w, "Methodologies", func(y float64) float64 {
			setDejaVu(pdf, "", cvFontSmall)
			text := "Agile/Scrum · RESTful API design · BFF pattern · Microservices · CI/CD · Unit testing · Code review · SOLID · Design patterns · System design documentation"
			return pdfMC(pdf, x, y, w, cvLineTight, text)
		})
	}
	return y
}

func pdfFillLeftColumn(pdf *gofpdf.Fpdf, x, y, targetY, w float64, doc CVDocument) float64 {
	if doc.YearsExperience > 0 && y < targetY-cvColumnFillMinGap {
		y = pdfSection(pdf, x, y, w, "Experience Level", func(y float64) float64 {
			setDejaVu(pdf, "", cvFontBody)
			return pdfMC(pdf, x, y, w, cvLineBody, formatYearsExperience(doc.YearsExperience))
		})
	}
	if len(doc.PrimaryStack) > 0 && y < targetY-cvColumnFillMinGap {
		y = pdfSection(pdf, x, y, w, "Primary Stack", func(y float64) float64 {
			setDejaVu(pdf, "", cvFontSmall)
			return pdfMC(pdf, x, y, w, cvLineTight, strings.Join(doc.PrimaryStack, " · "))
		})
	}
	return y
}

func formatYearsExperience(years float32) string {
	if years <= 0 {
		return ""
	}
	if years == float32(int(years)) {
		return fmt.Sprintf("%d+ years professional software engineering", int(years))
	}
	return fmt.Sprintf("%.1f years professional software engineering", years)
}
