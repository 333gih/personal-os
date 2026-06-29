package jobscout

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/cv"
	"github.com/personal-os/backend/internal/models"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type SearchPreferences struct {
	FocusSkills       []string `json:"focus_skills"`
	YearsExperience   float32  `json:"years_experience"`
	TargetRole        string   `json:"target_role"`
	WorkLocationTypes []string `json:"work_location_types"`
	EmploymentTypes   []string `json:"employment_types"`
	DailyScanEnabled  bool     `json:"daily_scan_enabled"`
	PushEnabled       bool     `json:"push_enabled"`
	Timezone          string   `json:"timezone"`
	LastScanAt        *time.Time `json:"last_scan_at,omitempty"`
	AvailableSkills   []string `json:"available_skills,omitempty"`
}

func defaultPreferences() SearchPreferences {
	return SearchPreferences{
		FocusSkills:       []string{"Java", "Spring Boot"},
		YearsExperience:   3.5,
		TargetRole:        "Software Engineer",
		WorkLocationTypes: []string{models.WorkLocationRemote, models.WorkLocationHybrid},
		EmploymentTypes:   []string{models.EmploymentFullTime},
		DailyScanEnabled:  true,
		PushEnabled:       true,
		Timezone:          dailyScanLocation,
	}
}

func (s *Service) GetPreferences(userID uuid.UUID) (*SearchPreferences, error) {
	prefs := defaultPreferences()
	prefs.AvailableSkills = s.collectAvailableSkills(userID)

	var row models.JobSearchPreferences
	err := s.db.Where("user_id = ?", userID).First(&row).Error
	if err == gorm.ErrRecordNotFound {
		s.seedPreferencesFromCV(userID, &prefs)
		return &prefs, nil
	}
	if err != nil {
		return nil, err
	}
	applyRow(&prefs, row)
	if len(prefs.FocusSkills) == 0 {
		s.seedPreferencesFromCV(userID, &prefs)
	}
	return &prefs, nil
}

func (s *Service) SavePreferences(userID uuid.UUID, in SearchPreferences) (*SearchPreferences, error) {
	in.FocusSkills = dedupeStrings(in.FocusSkills)
	if len(in.FocusSkills) == 0 {
		in.FocusSkills = []string{"Java", "Spring Boot"}
	}
	if in.YearsExperience <= 0 {
		in.YearsExperience = 3
	}
	if len(in.WorkLocationTypes) == 0 {
		in.WorkLocationTypes = []string{models.WorkLocationRemote}
	}
	if len(in.EmploymentTypes) == 0 {
		in.EmploymentTypes = []string{models.EmploymentFullTime}
	}
	in.TargetRole = strings.TrimSpace(in.TargetRole)

	focusJSON, _ := json.Marshal(in.FocusSkills)
	locJSON, _ := json.Marshal(in.WorkLocationTypes)
	empJSON, _ := json.Marshal(in.EmploymentTypes)

	row := models.JobSearchPreferences{
		UserID:            userID,
		FocusSkills:       focusJSON,
		YearsExperience:   in.YearsExperience,
		TargetRole:        in.TargetRole,
		WorkLocationTypes: locJSON,
		EmploymentTypes:   empJSON,
		DailyScanEnabled:  in.DailyScanEnabled,
		PushEnabled:       in.PushEnabled,
		Timezone:          strings.TrimSpace(in.Timezone),
		UpdatedAt:         time.Now().UTC(),
	}
	if row.Timezone == "" {
		row.Timezone = dailyScanLocation
	}
	if err := s.db.Clauses(clause.OnConflict{
		Columns: []clause.Column{{Name: "user_id"}},
		DoUpdates: clause.AssignmentColumns([]string{
			"focus_skills", "years_experience", "target_role",
			"work_location_types", "employment_types",
			"daily_scan_enabled", "push_enabled", "timezone", "updated_at",
		}),
	}).Create(&row).Error; err != nil {
		return nil, err
	}

	s.syncPreferencesToCV(userID, in)

	out := in
	out.AvailableSkills = s.collectAvailableSkills(userID)
	return &out, nil
}

func (s *Service) syncPreferencesToCV(userID uuid.UUID, prefs SearchPreferences) {
	if s.cv == nil {
		return
	}
	doc, err := s.cv.Get(userID)
	if err != nil {
		return
	}
	cvDoc := doc.Document
	cvDoc.PrimaryStack = append([]string(nil), prefs.FocusSkills...)
	cvDoc.YearsExperience = prefs.YearsExperience
	if prefs.TargetRole != "" {
		name, _ := splitCVHeadline(cvDoc.Headline)
		if name == "" {
			name = "Software Engineer"
		}
		cvDoc.Headline = name + " — " + prefs.TargetRole
	}
	for _, skill := range prefs.FocusSkills {
		s.addSkillToGroups(&cvDoc, skill)
	}
	cv.NormalizeDocument(&cvDoc)
	_, _ = s.cv.Save(userID, cvDoc)
}

func splitCVHeadline(headline string) (name, role string) {
	headline = strings.TrimSpace(headline)
	for _, sep := range []string{" — ", " – ", " - ", " | "} {
		if i := strings.Index(headline, sep); i > 0 {
			return strings.TrimSpace(headline[:i]), strings.TrimSpace(headline[i+len(sep):])
		}
	}
	return headline, ""
}

func (s *Service) addSkillToGroups(doc *cv.CVDocument, skill string) {
	skill = strings.TrimSpace(skill)
	if skill == "" {
		return
	}
	for _, g := range doc.SkillGroups {
		for _, item := range g.Items {
			if strings.EqualFold(item, skill) {
				return
			}
		}
	}
	category := "Backend & APIs"
	lower := strings.ToLower(skill)
	switch {
	case strings.Contains(lower, "react") || strings.Contains(lower, "vue") || strings.Contains(lower, "angular"):
		category = "Frontend"
	case strings.Contains(lower, "postgres") || strings.Contains(lower, "mongo") || strings.Contains(lower, "redis"):
		category = "Database & Caching"
	case strings.Contains(lower, "aws") || strings.Contains(lower, "gcp") || strings.Contains(lower, "cloud"):
		category = "Cloud"
	}
	for i, g := range doc.SkillGroups {
		if g.Category == category {
			doc.SkillGroups[i].Items = append(doc.SkillGroups[i].Items, skill)
			return
		}
	}
	doc.SkillGroups = append(doc.SkillGroups, cv.SkillGroup{Category: category, Items: []string{skill}})
}

func (s *Service) collectAvailableSkills(userID uuid.UUID) []string {
	seen := map[string]bool{}
	var out []string
	add := func(s string) {
		s = strings.TrimSpace(s)
		if s == "" {
			return
		}
		key := strings.ToLower(s)
		if seen[key] {
			return
		}
		seen[key] = true
		out = append(out, s)
	}

	if s.cv != nil {
		if doc, err := s.cv.Get(userID); err == nil {
			for _, sk := range cv.AllSkills(doc.Document) {
				add(sk)
			}
		}
	}

	var techs []models.Entity
	_ = s.db.Where("user_id = ? AND type = ? AND status = ?", userID, models.TypeTechnology, "active").
		Order("title ASC").Limit(80).Find(&techs).Error
	for _, t := range techs {
		add(t.Title)
	}
	return out
}

func (s *Service) seedPreferencesFromCV(userID uuid.UUID, prefs *SearchPreferences) {
	if s.cv == nil {
		return
	}
	doc, err := s.cv.Get(userID)
	if err != nil {
		return
	}
	profile := cv.BuildStackProfile(doc.Document)
	if len(profile.PrimaryStack) > 0 {
		prefs.FocusSkills = append([]string(nil), profile.PrimaryStack...)
	}
	if profile.YearsExperience > 0 {
		prefs.YearsExperience = profile.YearsExperience
	}
	if profile.RoleTitle != "" {
		prefs.TargetRole = profile.RoleTitle
	}
}

func applyRow(prefs *SearchPreferences, row models.JobSearchPreferences) {
	_ = json.Unmarshal(row.FocusSkills, &prefs.FocusSkills)
	_ = json.Unmarshal(row.WorkLocationTypes, &prefs.WorkLocationTypes)
	_ = json.Unmarshal(row.EmploymentTypes, &prefs.EmploymentTypes)
	prefs.YearsExperience = row.YearsExperience
	prefs.TargetRole = row.TargetRole
	prefs.DailyScanEnabled = row.DailyScanEnabled
	prefs.PushEnabled = row.PushEnabled
	prefs.Timezone = row.Timezone
	prefs.LastScanAt = row.LastScanAt
	if prefs.Timezone == "" {
		prefs.Timezone = dailyScanLocation
	}
}

func (s *Service) buildMatchProfile(userID uuid.UUID) cv.StackProfile {
	prefs, err := s.GetPreferences(userID)
	if err != nil || prefs == nil {
		def := defaultPreferences()
		prefs = &def
	}

	profile := cv.StackProfile{
		PrimaryStack:    append([]string(nil), prefs.FocusSkills...),
		YearsExperience: prefs.YearsExperience,
		RoleTitle:       prefs.TargetRole,
	}
	if profile.RoleTitle == "" {
		profile.RoleTitle = "Software Engineer"
	}

	all := s.collectAvailableSkills(userID)
	if len(all) == 0 {
		all = defaultSkills()
	}
	profile.AllSkills = all

	var parts []string
	if prefs.TargetRole != "" {
		parts = append(parts, prefs.TargetRole)
	}
	parts = append(parts, "Main focus: "+strings.Join(prefs.FocusSkills, ", "))
	parts = append(parts, fmt.Sprintf("%.1f years experience", prefs.YearsExperience))
	if len(prefs.WorkLocationTypes) > 0 {
		parts = append(parts, "Preferred work location: "+strings.Join(prefs.WorkLocationTypes, ", "))
	}
	if len(prefs.EmploymentTypes) > 0 {
		parts = append(parts, "Employment type: "+strings.Join(prefs.EmploymentTypes, ", "))
	}

	if s.cv != nil {
		if doc, err := s.cv.Get(userID); err == nil {
			if doc.Document.Summary != "" {
				parts = append(parts, doc.Document.Summary)
			}
		}
	}
	profile.ProfileText = strings.Join(parts, "\n")
	return profile
}

func dedupeStrings(items []string) []string {
	seen := map[string]bool{}
	var out []string
	for _, s := range items {
		s = strings.TrimSpace(s)
		if s == "" || seen[strings.ToLower(s)] {
			continue
		}
		seen[strings.ToLower(s)] = true
		out = append(out, s)
	}
	return out
}
