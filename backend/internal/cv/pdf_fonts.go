package cv

import (
	"embed"
	"io/fs"
	"os"
	"path/filepath"
	"sync"

	"github.com/jung-kurt/gofpdf"
)

//go:embed fonts/*.ttf
var cvFontFS embed.FS

var (
	fontDirOnce sync.Once
	fontDir     string
	fontDirErr  error
)

func cvFontDir() (string, error) {
	fontDirOnce.Do(func() {
		fontDir, fontDirErr = os.MkdirTemp("", "personal-os-cv-fonts-*")
		if fontDirErr != nil {
			return
		}
		entries, err := fs.ReadDir(cvFontFS, "fonts")
		if err != nil {
			fontDirErr = err
			return
		}
		for _, entry := range entries {
			if entry.IsDir() {
				continue
			}
			data, err := cvFontFS.ReadFile("fonts/" + entry.Name())
			if err != nil {
				fontDirErr = err
				return
			}
			dest := filepath.Join(fontDir, entry.Name())
			if err := os.WriteFile(dest, data, 0o644); err != nil {
				fontDirErr = err
				return
			}
		}
	})
	return fontDir, fontDirErr
}

func newCVPDF() (*gofpdf.Fpdf, error) {
	dir, err := cvFontDir()
	if err != nil {
		return nil, err
	}

	pdf := gofpdf.New("P", "mm", "A4", dir)
	pdf.SetMargins(cvMarginL, cvMarginT, cvMarginR)
	pdf.SetAutoPageBreak(true, cvMarginB)

	for _, spec := range []struct{ style, file string }{
		{"", "DejaVuSans.ttf"},
		{"B", "DejaVuSans-Bold.ttf"},
		{"I", "DejaVuSans-Oblique.ttf"},
	} {
		pdf.AddUTF8Font("DejaVu", spec.style, spec.file)
	}

	return pdf, nil
}

func setDejaVu(pdf *gofpdf.Fpdf, style string, size float64) {
	pdf.SetFont("DejaVu", style, size)
}
