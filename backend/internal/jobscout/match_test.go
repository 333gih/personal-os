package jobscout

import (
	"testing"

	"github.com/personal-os/backend/internal/cv"
)

func TestPreScorePrimaryStackJava(t *testing.T) {
	profile := cv.StackProfile{
		PrimaryStack: []string{"Java", "Spring Boot", "AEM"},
		AllSkills:    []string{"Java", "Spring Boot", "AEM", "PostgreSQL", "Redis"},
	}
	job := rawJob{
		Title:       "Senior Java Spring Boot Developer",
		Description: "Build microservices with Spring Boot and deploy to GCP.",
		Skills:      []string{"java", "spring"},
	}
	score, hits, primary := preScoreJob(profile, job)
	if !primary {
		t.Fatalf("expected primary match")
	}
	if score < PrimaryMatchFloor {
		t.Fatalf("score %v below primary floor %v", score, PrimaryMatchFloor)
	}
	if len(hits) == 0 {
		t.Fatalf("expected hits")
	}
}

func TestPreScoreUnrelatedLow(t *testing.T) {
	profile := cv.StackProfile{
		PrimaryStack: []string{"Java", "Spring Boot"},
		AllSkills:    []string{"Java", "Spring Boot"},
	}
	job := rawJob{
		Title:       "Ruby on Rails Developer",
		Description: "Rails monolith and PostgreSQL only.",
	}
	score, _, primary := preScoreJob(profile, job)
	if primary {
		t.Fatalf("unexpected primary match")
	}
	if score >= MinMatchScore {
		t.Fatalf("expected low score, got %v", score)
	}
}
