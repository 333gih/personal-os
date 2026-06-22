package cv

import (
	"github.com/jung-kurt/gofpdf"
)

const cvColumnFillMinGap = 3.0 // mm

type pdfRightSpacing struct {
	blockExtra float64
	lineExtra  float64
}

var pdfRightLayout pdfRightSpacing

func resetPDFRightSpacing() {
	pdfRightLayout = pdfRightSpacing{}
}

func setPDFRightSpacing(blockExtra, lineExtra float64) {
	pdfRightLayout.blockExtra = blockExtra
	pdfRightLayout.lineExtra = lineExtra
}

func pdfRoleBlockGap() float64 {
	return cvBlockGap + pdfRightLayout.blockExtra
}

func pdfRoleLineHeight() float64 {
	return cvLineTight + pdfRightLayout.lineExtra
}

func pdfColumnTargetY(pageH float64) float64 {
	return pageH - cvMarginB - 2
}

func countRightBlocks(doc CVDocument) int {
	n := len(doc.Experience)
	grouped := projectsByCompany(doc.Projects)
	for _, exp := range doc.Experience {
		n += len(grouped[companyKey(exp.Company)])
	}
	n += len(grouped["_ungrouped"])
	if n == 0 {
		return 1
	}
	return n
}

// pdfBalanceColumns re-renders the right column with extra spacing when it is shorter than the left.
func pdfBalanceColumns(pdf *gofpdf.Fpdf, rightX, columnStartY, rightW, leftEndY, rightEndY, pageH float64, doc CVDocument) float64 {
	targetY := leftEndY
	pageTarget := pdfColumnTargetY(pageH)
	if pageTarget > targetY {
		targetY = pageTarget
	}

	if rightEndY >= targetY-cvColumnFillMinGap {
		return rightEndY
	}

	blocks := countRightBlocks(doc)
	gap := targetY - rightEndY
	blockExtra := (gap * 0.55) / float64(blocks)
	lineExtra := 0.15
	if blockExtra > 2.5 {
		blockExtra = 2.5
	}

	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(rightX, columnStartY, rightW, pageH-columnStartY-cvMarginB, "F")
	pdf.SetFillColor(0, 0, 0)

	setPDFRightSpacing(blockExtra, lineExtra)
	return renderPDFRightColumn(pdf, rightX, columnStartY, rightW, doc)
}
