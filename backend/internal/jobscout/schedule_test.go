package jobscout

import (
	"testing"

	"github.com/personal-os/backend/internal/cv"
	"github.com/personal-os/backend/internal/models"
)

func TestScanSkillsForUser(t *testing.T) {
	t.Parallel()
	prefs := SearchPreferences{FocusSkills: []string{"Java", "Spring Boot"}}
	profile := cv.StackProfile{
		PrimaryStack: []string{"Java"},
		AllSkills:    []string{"Java", "Spring Boot", "PostgreSQL", "Docker"},
	}
	got := scanSkillsForUser(prefs, profile)
	if len(got) < 3 {
		t.Fatalf("got %v", got)
	}
	if got[0] != "Java" || got[1] != "Spring Boot" {
		t.Fatalf("focus first: %v", got)
	}
}

func TestFormatJobTitles(t *testing.T) {
	t.Parallel()
	body := formatJobTitles([]models.JobOpportunity{
		{Title: "Java Dev", Company: "FPT"},
	})
	if body == "" {
		t.Fatal("expected body")
	}
}

func TestDefaultPreferencesSchedule(t *testing.T) {
	t.Parallel()
	p := defaultPreferences()
	if !p.DailyScanEnabled || !p.PushEnabled {
		t.Fatal("defaults should enable daily scan and push")
	}
	if p.Timezone != dailyScanLocation {
		t.Fatalf("timezone=%q", p.Timezone)
	}
}
