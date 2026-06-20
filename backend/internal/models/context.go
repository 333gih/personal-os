package models

import "strings"

// AIEntityType maps domain/type to the coarse AI context type used for indexing and Qdrant payloads.
func AIEntityType(domain, entityType string) string {
	switch domain {
	case DomainLearning:
		return AITypeLearning
	case DomainStartup:
		return AITypeStartup
	case DomainGoal:
		return AITypeGoal
	case DomainJournal:
		return AITypeJournal
	case DomainWork:
		return AITypeWork
	}
	if strings.HasPrefix(entityType, "goal_") {
		return AITypeGoal
	}
	if strings.HasPrefix(entityType, "journal_") {
		return AITypeJournal
	}
	if strings.HasPrefix(entityType, "learning_") {
		return AITypeLearning
	}
	if strings.HasPrefix(entityType, "startup_") {
		return AITypeStartup
	}
	if strings.HasPrefix(entityType, "work_") {
		return AITypeWork
	}
	if strings.HasPrefix(entityType, "entertainment_") {
		return AITypeBook
	}
	return AITypeTask
}
