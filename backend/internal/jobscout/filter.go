package jobscout

import (
	"strings"

	"github.com/personal-os/backend/internal/models"
)

func jobMatchesPreferences(job rawJob, prefs SearchPreferences) bool {
	if len(prefs.WorkLocationTypes) == 0 && len(prefs.EmploymentTypes) == 0 {
		return true
	}
	hay := strings.ToLower(job.Title + " " + job.Location + " " + job.Description)

	if len(prefs.WorkLocationTypes) > 0 && !containsAny(prefs.WorkLocationTypes, models.WorkLocationAnywhere) {
		if !locationMatches(hay, job.Location, prefs.WorkLocationTypes) {
			return false
		}
	}

	if len(prefs.EmploymentTypes) > 0 {
		if !employmentMatches(hay, prefs.EmploymentTypes) {
			// Allow jobs with no explicit employment type mention
			if hasExplicitEmploymentConflict(hay, prefs.EmploymentTypes) {
				return false
			}
		}
	}
	return true
}

func locationMatches(hay, location string, types []string) bool {
	loc := strings.ToLower(strings.TrimSpace(location))
	for _, t := range types {
		switch t {
		case models.WorkLocationRemote:
			if strings.Contains(hay, "remote") || strings.Contains(hay, "work from home") ||
				strings.Contains(hay, "wfh") || strings.Contains(loc, "remote") ||
				strings.Contains(loc, "worldwide") || strings.Contains(loc, "anywhere") {
				return true
			}
		case models.WorkLocationHybrid:
			if strings.Contains(hay, "hybrid") {
				return true
			}
		case models.WorkLocationOnsite:
			if strings.Contains(hay, "on-site") || strings.Contains(hay, "onsite") ||
				strings.Contains(hay, "in-office") || strings.Contains(hay, "in office") {
				return true
			}
		case models.WorkLocationAnywhere:
			return true
		}
	}
	// Remote job boards often omit location detail — treat empty/remote-ish as OK for remote seekers
	if containsAny(types, models.WorkLocationRemote) {
		if loc == "" || strings.Contains(loc, "remote") {
			return true
		}
	}
	return false
}

func employmentMatches(hay string, types []string) bool {
	for _, t := range types {
		switch t {
		case models.EmploymentFullTime:
			if strings.Contains(hay, "full-time") || strings.Contains(hay, "full time") ||
				strings.Contains(hay, "permanent") {
				return true
			}
		case models.EmploymentContract:
			if strings.Contains(hay, "contract") || strings.Contains(hay, "freelance") {
				return true
			}
		case models.EmploymentPartTime:
			if strings.Contains(hay, "part-time") || strings.Contains(hay, "part time") {
				return true
			}
		case models.EmploymentInternship:
			if strings.Contains(hay, "intern") {
				return true
			}
		case models.EmploymentTemporary:
			if strings.Contains(hay, "temporary") || strings.Contains(hay, "temp ") {
				return true
			}
		}
	}
	return false
}

func hasExplicitEmploymentConflict(hay string, selected []string) bool {
	wantFull := containsAny(selected, models.EmploymentFullTime)
	if wantFull && (strings.Contains(hay, "part-time") || strings.Contains(hay, "part time") ||
		strings.Contains(hay, "internship") || strings.Contains(hay, "intern only")) {
		return true
	}
	if containsAny(selected, models.EmploymentInternship) {
		return strings.Contains(hay, "senior") && !strings.Contains(hay, "intern")
	}
	return false
}

func containsAny(list []string, item string) bool {
	for _, v := range list {
		if v == item {
			return true
		}
	}
	return false
}

func preferenceLocationBonus(job rawJob, prefs SearchPreferences) float32 {
	hay := strings.ToLower(job.Title + " " + job.Location + " " + job.Description)
	if locationMatches(hay, job.Location, prefs.WorkLocationTypes) {
		return 0.05
	}
	return 0
}
