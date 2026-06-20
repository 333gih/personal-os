package models

import "testing"

func TestAIEntityType(t *testing.T) {
	tests := []struct {
		domain, entityType, want string
	}{
		{DomainLearning, TypeCourse, AITypeLearning},
		{DomainStartup, TypeStartupIdea, AITypeStartup},
		{DomainWork, TypeWorkProject, AITypeWork},
		{DomainGoal, TypeGoalHabit, AITypeGoal},
		{DomainJournal, TypeJournalEntry, AITypeJournal},
		{DomainInbox, TypeInboxNote, AITypeTask},
		{"", "entertainment_story", AITypeBook},
	}
	for _, tc := range tests {
		if got := AIEntityType(tc.domain, tc.entityType); got != tc.want {
			t.Errorf("AIEntityType(%q, %q) = %q, want %q", tc.domain, tc.entityType, got, tc.want)
		}
	}
}

func TestDomainForTypeGoalJournal(t *testing.T) {
	if DomainForType(TypeGoalHabit) != DomainGoal {
		t.Fatalf("goal habit domain")
	}
	if DomainForType(TypeJournalReflection) != DomainJournal {
		t.Fatalf("journal reflection domain")
	}
}
