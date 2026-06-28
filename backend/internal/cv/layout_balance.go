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
	if scale < cvLayoutMinScale {
		scale = cvLayoutMinScale
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
	return pageH - cvMarginB - cvColumnBottomPad
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
	pageTarget := pdfColumnTargetY(pageH)
	taller := leftEndY
	if rightEndY > taller {
		taller = rightEndY
	}
	if taller > pageTarget {
		return pageTarget
	}
	return pageTarget
}

func pdfWipeColumnArea(pdf *gofpdf.Fpdf, leftX, rightX, columnStartY, leftW, rightW, pageH float64) {
	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(leftX, columnStartY, leftW, pageH-columnStartY-cvMarginB, "F")
	pdf.Rect(rightX, columnStartY, rightW, pageH-columnStartY-cvMarginB, "F")
	pdf.SetFillColor(0, 0, 0)
}

func pdfRenderColumns(pdf *gofpdf.Fpdf, leftX, rightX, columnStartY, leftW, rightW float64, doc CVDocument) (float64, float64) {
	leftEndY := renderPDFLeftColumn(pdf, leftX, columnStartY, leftW, doc)
	rightEndY := renderPDFRightColumn(pdf, rightX, columnStartY, rightW, doc)
	return leftEndY, rightEndY
}

func pdfFitColumnsToPage(pdf *gofpdf.Fpdf, leftX, rightX, columnStartY, leftW, rightW, pageH float64, doc CVDocument) (float64, float64) {
	pageTarget := pdfColumnTargetY(pageH)
	variants := layoutDocumentVariants(doc)

	for _, variant := range variants {
		for scale := 1.0; scale >= cvLayoutMinScale-0.001; scale -= 0.02 {
			setPDFCompressScale(scale)
			resetPDFRightSpacing()
			resetPDFLeftSpacing()
			pdfWipeColumnArea(pdf, leftX, rightX, columnStartY, leftW, rightW, pageH)

			leftEndY, rightEndY := pdfRenderColumns(pdf, leftX, rightX, columnStartY, leftW, rightW, variant)
			maxY := leftEndY
			if rightEndY > maxY {
				maxY = rightEndY
			}
			if maxY <= pageTarget+cvColumnFillMinGap*0.5 {
				return leftEndY, rightEndY
			}
		}
	}

	setPDFCompressScale(cvLayoutMinScale)
	resetPDFRightSpacing()
	resetPDFLeftSpacing()
	pdfWipeColumnArea(pdf, leftX, rightX, columnStartY, leftW, rightW, pageH)
	heavy := trimDocumentForLayout(prepareDocumentForPDF(doc), trimHeavy)
	return pdfRenderColumns(pdf, leftX, rightX, columnStartY, leftW, rightW, heavy)
}

func pdfBalanceRightColumn(pdf *gofpdf.Fpdf, rightX, columnStartY, rightW, rightEndY, targetY, pageH float64, doc CVDocument) float64 {
	pageTarget := pdfColumnTargetY(pageH)
	if rightEndY > pageTarget || rightEndY >= targetY-cvColumnFillMinGap {
		return rightEndY
	}

	blocks := countRightBlocks(doc)
	gap := targetY - rightEndY
	blockExtra := (gap * 0.60) / float64(blocks)
	lineExtra := gap * 0.015
	if blockExtra > 5.0 {
		blockExtra = 5.0
	}
	if lineExtra > 0.35 {
		lineExtra = 0.35
	}

	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(rightX, columnStartY, rightW, pageH-columnStartY-cvMarginB, "F")
	pdf.SetFillColor(0, 0, 0)

	setPDFRightSpacing(blockExtra, lineExtra)
	return renderPDFRightColumn(pdf, rightX, columnStartY, rightW, doc)
}

func pdfBalanceLeftColumn(pdf *gofpdf.Fpdf, leftX, columnStartY, leftW, leftEndY, targetY, pageH float64, doc CVDocument) float64 {
	pageTarget := pdfColumnTargetY(pageH)
	if leftEndY > pageTarget || leftEndY >= targetY-cvColumnFillMinGap {
		return leftEndY
	}

	sections := countLeftSections(doc)
	blocks := countLeftBlocks(doc)
	gap := targetY - leftEndY
	sectionExtra := (gap * 0.45) / float64(sections)
	blockExtra := (gap * 0.40) / float64(blocks)
	lineExtra := gap * 0.012
	if sectionExtra > 3.5 {
		sectionExtra = 3.5
	}
	if blockExtra > 2.5 {
		blockExtra = 2.5
	}
	if lineExtra > 0.30 {
		lineExtra = 0.30
	}

	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(leftX, columnStartY, leftW, pageH-columnStartY-cvMarginB, "F")
	pdf.SetFillColor(0, 0, 0)

	setPDFLeftSpacing(sectionExtra, lineExtra, blockExtra)
	return renderPDFLeftColumn(pdf, leftX, columnStartY, leftW, doc)
}

func pdfClipColumnOverflow(pdf *gofpdf.Fpdf, leftX, rightX, columnStartY, leftW, rightW, pageH float64) {
	clipY := pdfColumnTargetY(pageH) + 0.5
	height := pageH - clipY
	if height <= 0 {
		return
	}
	pdf.SetFillColor(255, 255, 255)
	pdf.Rect(leftX, clipY, leftW, height, "F")
	pdf.Rect(rightX, clipY, rightW, height, "F")
	pdf.SetFillColor(0, 0, 0)
}

// pdfBalanceColumns re-renders whichever column is shorter so both reach the same bottom edge.
func pdfBalanceColumns(pdf *gofpdf.Fpdf, leftX, rightX, columnStartY, leftW, rightW, leftEndY, rightEndY, pageH float64, doc CVDocument) (float64, float64) {
	pageTarget := pdfColumnTargetY(pageH)
	if leftEndY > pageTarget || rightEndY > pageTarget {
		pdfClipColumnOverflow(pdf, leftX, rightX, columnStartY, leftW, rightW, pageH)
		return leftEndY, rightEndY
	}

	targetY := pdfColumnTarget(leftEndY, rightEndY, pageH)

	rightEndY = pdfBalanceRightColumn(pdf, rightX, columnStartY, rightW, rightEndY, targetY, pageH, doc)
	leftEndY = pdfBalanceLeftColumn(pdf, leftX, columnStartY, leftW, leftEndY, targetY, pageH, doc)

	// Second pass if one column still shorter after first stretch.
	if leftEndY < targetY-cvColumnFillMinGap || rightEndY < targetY-cvColumnFillMinGap {
		rightEndY = pdfBalanceRightColumn(pdf, rightX, columnStartY, rightW, rightEndY, targetY, pageH, doc)
		leftEndY = pdfBalanceLeftColumn(pdf, leftX, columnStartY, leftW, leftEndY, targetY, pageH, doc)
	}

	return leftEndY, rightEndY
}
