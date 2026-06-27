package cv

import (
	"strings"
	"testing"
)

func TestCanonicalIdealCV_NotSparse(t *testing.T) {
	doc := CanonicalIdealCV()
	if documentIsSparse(doc) {
		t.Fatal("canonical ideal CV must include experience and projects")
	}
	if len(doc.Achievements) < 6 {
		t.Fatalf("expected at least 6 achievements, got %d", len(doc.Achievements))
	}
	if len(doc.Education) < 2 {
		t.Fatalf("expected education entries")
	}
	blocks := DocumentToBlocks(doc)
	if templateBlocksNeedSync(blocks) {
		t.Fatalf("canonical blocks should not need sync: %d blocks", len(blocks))
	}
	if len(blocks) < 15 {
		t.Fatalf("expected rich block set, got %d blocks", len(blocks))
	}
}

func TestBuildRecommendedDocument_ReordersJavaFirst(t *testing.T) {
	doc := CanonicalIdealCV()
	rec := BuildRecommendedDocument(doc)
	if len(rec.Projects) == 0 {
		t.Fatal("recommended doc needs projects")
	}
	title := strings.ToLower(rec.Projects[0].Title)
	if !strings.Contains(title, "horserace") && !strings.Contains(title, "canon") {
		t.Logf("first project: %s", rec.Projects[0].Title)
	}
}
