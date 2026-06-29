//go:build integration

package jobscout

import (
	"context"
	"testing"
)

func TestProbeTopCVHTML(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	body, status, err := fetchHTML(ctx, "https://www.topcv.vn/tim-viec-lam-java")
	if err != nil {
		t.Fatalf("fetch: %v", err)
	}
	if status != 200 {
		t.Skipf("topcv returned http %d (datacenter IP often blocked)", status)
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
