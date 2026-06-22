package cv

import (
	"github.com/jung-kurt/gofpdf"
)

const cvColumnFillMinGap = 3.0 // mm

type pdfRightSpacing struct {
	blockExtra float64
	lineExtra  float64
}

type pdfLeftSpacing struct {
	sectionExtra float64
	lineExtra    float64
	blockExtra   float64
}

var pdfRightLayout pdfRightSpacing
var pdfLeftLayout pdfLeftSpacing
var pdfCompressScale = 1.0

func resetPDFCompressScale() {
	pdfCompressScale = 1.0
}

func setPDFCompressScale(scale float64) {
	if scale < 0.84 {
		scale = 0.84
	}
	pdfCompressScale = scale
}

func pdfScale(v float64) float64 {
	return v * pdfCompressScale
}

func resetPDFRightSpacing() {
	pdfRightLayout = pdfRightSpacing{}
}

func resetPDFLeftSpacing() {
	pdfLeftLayout = pdfLeftSpacing{}
}

func setPDFRightSpacing(blockExtra, lineExtra float64) {
	pdfRightLayout.blockExtra = blockExtra
	pdfRightLayout.lineExtra = lineExtra
}

func setPDFLeftSpacing(sectionExtra, lineExtra, blockExtra float64) {
	pdfLeftLayout.sectionExtra = sectionExtra
	pdfLeftLayout.lineExtra = lineExtra
	pdfLeftLayout.blockExtra = blockExtra
}

func pdfLeftSectionGap() float64 {
	return pdfScale(cvSectionGap) + pdfLeftLayout.sectionExtra
}

func pdfLeftLineHeight() float64 {
	return pdfScale(cvLineTight) + pdfLeftLayout.lineExtra
}

func pdfLeftBlockGap() float64 {
	return pdfScale(1.0) + pdfLeftLayout.blockExtra
}

func pdfRoleBlockGap() float64 {
	return pdfScale(cvBlockGap) + pdfRightLayout.blockExtra
}

func pdfRoleLineHeight() float64 {
	return pdfScale(cvLineTight) + pdfRightLayout.lineExtra
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

func countLeftSections(doc CVDocument) int {
	n := 0
	if doc.Summary != "" {
		n++
	}
	if len(doc.Education) > 0 {
		n++
	}
	if len(doc.SkillGroups) > 0 || len(doc.Skills) > 0 {
		n++
	}
	if len(doc.Achievements) > 0 {
		n++
	}
	if len(doc.Certificates) > 0 {
		n++
	}
	if n == 0 {
		return 1
	}
	return n
}

func countLeftBlocks(doc CVDocument) int {
	n := 0
	if doc.Summary != "" {
		n++
	}
	n += len(doc.Education)
	if len(doc.SkillGroups) > 0 {
		n += len(doc.SkillGroups)
	} else if len(doc.Skills) > 0 {
		n++
	}
	n += len(doc.Achievements)
	n += len(doc.Certificates)
	if n == 0 {
		return 1
	}
	return n
}

func pdfColumnTarget(leftEndY, rightEndY, pageH float64) float64 {
	targetY := leftEndY
	if rightEndY > targetY {
		targetY = rightEndY
	}
	pageTarget := pdfColumnTargetY(pageH)
	if targetY > pageTarget {
		return pageTarget
	}
	if pageTarget > targetY {
		return pageTarget
	}
	return targetY
}

func pdfWipeColumnArea(pdf *gofpdf.Fpdf, leftX, rightX, columnStartY, leftW, rightW, pageH float64) {
	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(leftX, columnStartY, leftW, pageH-columnStartY-cvMarginB, "F")
	pdf.Rect(rightX, columnStartY, rightW, pageH-columnStartY-cvMarginB, "F")
	pdf.SetFillColor(0, 0, 0)
}

func pdfFitColumnsToPage(pdf *gofpdf.Fpdf, leftX, rightX, columnStartY, leftW, rightW, pageH float64, doc CVDocument) (float64, float64) {
	pageTarget := pdfColumnTargetY(pageH)
	leftEndY := columnStartY
	rightEndY := columnStartY

	for scale := 1.0; scale >= 0.84; scale -= 0.04 {
		setPDFCompressScale(scale)
		resetPDFRightSpacing()
		resetPDFLeftSpacing()
		pdfWipeColumnArea(pdf, leftX, rightX, columnStartY, leftW, rightW, pageH)

		leftEndY = renderPDFLeftColumn(pdf, leftX, columnStartY, leftW, doc)
		rightEndY = renderPDFRightColumn(pdf, rightX, columnStartY, rightW, doc)

		maxY := leftEndY
		if rightEndY > maxY {
			maxY = rightEndY
		}
		if maxY <= pageTarget+cvColumnFillMinGap {
			break
		}
	}

	return leftEndY, rightEndY
}

func pdfBalanceRightColumn(pdf *gofpdf.Fpdf, rightX, columnStartY, rightW, rightEndY, targetY, pageH float64, doc CVDocument) float64 {
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

func pdfBalanceLeftColumn(pdf *gofpdf.Fpdf, leftX, columnStartY, leftW, leftEndY, targetY, pageH float64, doc CVDocument) float64 {
	if leftEndY >= targetY-cvColumnFillMinGap {
		return leftEndY
	}

	sections := countLeftSections(doc)
	blocks := countLeftBlocks(doc)
	gap := targetY - leftEndY
	sectionExtra := (gap * 0.40) / float64(sections)
	blockExtra := (gap * 0.35) / float64(blocks)
	lineExtra := 0.12
	if sectionExtra > 2.0 {
		sectionExtra = 2.0
	}
	if blockExtra > 1.5 {
		blockExtra = 1.5
	}

	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(leftX, columnStartY, leftW, pageH-columnStartY-cvMarginB, "F")
	pdf.SetFillColor(0, 0, 0)

	setPDFLeftSpacing(sectionExtra, lineExtra, blockExtra)
	return renderPDFLeftColumn(pdf, leftX, columnStartY, leftW, doc)
}

// pdfBalanceColumns re-renders whichever column is shorter so both reach the same bottom edge.
func pdfBalanceColumns(pdf *gofpdf.Fpdf, leftX, rightX, columnStartY, leftW, rightW, leftEndY, rightEndY, pageH float64, doc CVDocument) (float64, float64) {
	targetY := pdfColumnTarget(leftEndY, rightEndY, pageH)

	resetPDFRightSpacing()
	resetPDFLeftSpacing()

	rightEndY = pdfBalanceRightColumn(pdf, rightX, columnStartY, rightW, rightEndY, targetY, pageH, doc)
	leftEndY = pdfBalanceLeftColumn(pdf, leftX, columnStartY, leftW, leftEndY, targetY, pageH, doc)

	return leftEndY, rightEndY
}
