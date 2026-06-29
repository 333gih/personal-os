package jobscout

import (
	"context"
	"testing"
)

func TestProbeTopCVHTML(t *testing.T) {
	if testing.Short() {
		t.Skip("network")
	}
	t.Parallel()
	ctx := context.Background()
	body, status, err := fetchHTML(ctx, "https://www.topcv.vn/tim-viec-lam-java")
	if err != nil {
		t.Fatalf("fetch: %v", err)
	}
	t.Logf("status=%d len=%d count=%d", status, len(body), parseTopCVJobCount(body))
	jobs, err := parseTopCVListHTML(body, "java")
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	t.Logf("jobs=%d sample=%+v", len(jobs), firstJob(jobs))
}

func firstJob(jobs []rawJob) rawJob {
	if len(jobs) == 0 {
		return rawJob{}
	}
	return jobs[0]
}

func TestParseTopCVFixture(t *testing.T) {
	t.Parallel()
	html := `### Java Developer
https://www.topcv.vn/viec-lam/java-developer/2209073.html?ta_source=JobSearchList
<p>Tuyển dụng 85 việc làm Java</p>`
	jobs, err := parseTopCVListHTML(html, "java")
	if err != nil {
		t.Fatal(err)
	}
	if len(jobs) != 1 {
		t.Fatalf("want 1 got %d", len(jobs))
	}
	if jobs[0].Source != "topcv" || jobs[0].ExternalID != "2209073" {
		t.Fatalf("bad job %+v", jobs[0])
	}
	if c := parseTopCVJobCount(html); c != 85 {
		t.Fatalf("count=%d", c)
	}
}

func TestVNLocationFilter(t *testing.T) {
	t.Parallel()
	job := rawJob{Location: "Vietnam", Source: "itviec", Title: "Java Dev"}
	prefs := SearchPreferences{WorkLocationTypes: []string{"hybrid", "remote"}}
	if !jobMatchesPreferences(job, prefs) {
		t.Fatal("expected vn hybrid match")
	}
}
