package studylearning

import (
	"encoding/json"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/learningimport"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/notification"
	"gorm.io/datatypes"
	"gorm.io/gorm"
)

const (
	kindStudySchedule = "study_schedule"
	kindLearningJob   = "learning_job"

	blockDSAMorning    = "dsa_commute"
	blockEnglishEvening = "english_commute"
	blockTOEICEvening  = "toeic_evening"

	dsaCourseID     = "c000000c-0001-4001-8001-000000000001"
	englishCourseID = "c000000c-0001-4001-8001-000000000023"
)

type Service struct {
	db       *gorm.DB
	learning *learningimport.Service
	notify   *notification.Service
}

func NewService(db *gorm.DB, learning *learningimport.Service, notify *notification.Service) *Service {
	return &Service{db: db, learning: learning, notify: notify}
}

type ScheduleDTO struct {
	WorkStartHour         int    `json:"work_start_hour"`
	WorkEndHour           int    `json:"work_end_hour"`
	WorkDays              []int  `json:"work_days"`
	CommuteMinutes        int    `json:"commute_minutes"`
	MorningCommuteTime    string `json:"morning_commute_time"`
	EveningCommuteTime    string `json:"evening_commute_time"`
	ToeicSessionTime      string `json:"toeic_session_time"`
	DsaCommuteMinutes     int    `json:"dsa_commute_minutes"`
	EnglishCommuteMinutes int    `json:"english_commute_minutes"`
	ToeicDailyMinutes     int    `json:"toeic_daily_minutes"`
	Timezone              string `json:"timezone"`
	PushEnabled           bool   `json:"push_enabled"`
}

type TodayBlock struct {
	ID              string    `json:"id"`
	Kind            string    `json:"kind"`
	Track           string    `json:"track"`
	Title           string    `json:"title"`
	Subtitle        string    `json:"subtitle"`
	StartAt         time.Time `json:"start_at"`
	DurationMinutes int       `json:"duration_minutes"`
	Mode            string    `json:"mode"`
	EntityID        string    `json:"entity_id,omitempty"`
	CommuteTip      string    `json:"commute_tip,omitempty"`
}

type TodayPlan struct {
	Date         string        `json:"date"`
	Timezone     string        `json:"timezone"`
	IsWorkDay    bool          `json:"is_work_day"`
	Blocks       []TodayBlock  `json:"blocks"`
	TotalMinutes int           `json:"total_minutes"`
	DSA          *DSADailyFocus `json:"dsa,omitempty"`
}

func (s *Service) GetSchedule(userID uuid.UUID) (*ScheduleDTO, error) {
	sched, err := s.ensureSchedule(userID)
	if err != nil {
		return nil, err
	}
	return scheduleToDTO(sched), nil
}

func (s *Service) PutSchedule(userID uuid.UUID, in ScheduleDTO) (*ScheduleDTO, error) {
	sched, err := s.ensureSchedule(userID)
	if err != nil {
		return nil, err
	}
	days, _ := json.Marshal(defaultWorkDays(in.WorkDays))
	sched.WorkStartHour = clamp(in.WorkStartHour, 5, 12, sched.WorkStartHour)
	sched.WorkEndHour = clamp(in.WorkEndHour, 14, 22, sched.WorkEndHour)
	sched.WorkDays = datatypes.JSON(days)
	sched.CommuteMinutes = clamp(in.CommuteMinutes, 10, 120, sched.CommuteMinutes)
	if t := normalizeTime(in.MorningCommuteTime); t != "" {
		sched.MorningCommuteTime = t
	}
	if t := normalizeTime(in.EveningCommuteTime); t != "" {
		sched.EveningCommuteTime = t
	}
	if t := normalizeTime(in.ToeicSessionTime); t != "" {
		sched.ToeicSessionTime = t
	}
	sched.DsaCommuteMinutes = clamp(in.DsaCommuteMinutes, 5, 60, sched.DsaCommuteMinutes)
	sched.EnglishCommuteMinutes = clamp(in.EnglishCommuteMinutes, 5, 45, sched.EnglishCommuteMinutes)
	sched.ToeicDailyMinutes = clamp(in.ToeicDailyMinutes, 15, 180, sched.ToeicDailyMinutes)
	if in.Timezone != "" {
		sched.Timezone = in.Timezone
	}
	sched.PushEnabled = in.PushEnabled
	sched.UpdatedAt = time.Now()
	if err := s.db.Save(sched).Error; err != nil {
		return nil, err
	}
	s.EnsureTodayReminders(userID)
	return scheduleToDTO(sched), nil
}

func (s *Service) Today(userID uuid.UUID) (*TodayPlan, error) {
	s.ensureCurriculum(userID)
	sched, err := s.ensureSchedule(userID)
	if err != nil {
		return nil, err
	}
	loc := loadLocation(sched.Timezone)
	now := time.Now().In(loc)
	plan := buildTodayPlan(sched, now)
	dsa, err := s.DSADailyFocus(userID)
	if err == nil && dsa != nil {
		plan.DSA = dsa
		enrichDSABlocks(plan, dsa)
	}
	s.EnsureTodayReminders(userID)
	return plan, nil
}

func (s *Service) EnsureTodayReminders(userID uuid.UUID) {
	plan, err := s.buildEnrichedTodayPlan(userID)
	if err != nil {
		log.Printf("studylearning: ensure today reminders: %v", err)
		return
	}
	s.ensureRemindersFromPlan(userID, plan)
}

func (s *Service) buildEnrichedTodayPlan(userID uuid.UUID) (*TodayPlan, error) {
	sched, err := s.ensureSchedule(userID)
	if err != nil {
		return nil, err
	}
	loc := loadLocation(sched.Timezone)
	now := time.Now().In(loc)
	plan := buildTodayPlan(sched, now)
	dsa, err := s.DSADailyFocus(userID)
	if err == nil && dsa != nil {
		plan.DSA = dsa
		enrichDSABlocks(plan, dsa)
	}
	return plan, nil
}

func (s *Service) ensureRemindersFromPlan(userID uuid.UUID, plan *TodayPlan) {
	for _, b := range plan.Blocks {
		if err := s.upsertStudyReminder(userID, b); err != nil {
			log.Printf("studylearning: skip reminder block=%s: %v", b.Kind, err)
		}
	}
}

func (s *Service) TodayBlocksOnly(userID uuid.UUID) (*TodayPlan, error) {
	sched, err := s.ensureSchedule(userID)
	if err != nil {
		return nil, err
	}
	loc := loadLocation(sched.Timezone)
	return buildTodayPlan(sched, time.Now().In(loc)), nil
}

func (s *Service) upsertStudyReminder(userID uuid.UUID, b TodayBlock) error {
	entityID, err := s.resolveReminderEntityID(userID, b)
	if err != nil {
		return err
	}
	if entityID == uuid.Nil {
		return fmt.Errorf("no learning entity for track=%s", b.Track)
	}
	dateKey := b.StartAt.Format("2006-01-02")
	idem := fmt.Sprintf("study:%s:%s:%s", userID, dateKey, b.Kind)

	var count int64
	s.db.Model(&models.Reminder{}).
		Where("user_id = ? AND kind = ? AND due_at = ? AND status = 'pending'", userID, kindStudySchedule, b.StartAt.UTC()).
		Count(&count)
	if count > 0 {
		return nil
	}

	meta, _ := json.Marshal(map[string]string{
		"block_kind": b.Kind,
		"track":      b.Track,
		"mode":       b.Mode,
		"idem":       idem,
	})
	rem := models.Reminder{
		UserID:   userID,
		EntityID: entityID,
		Title:    b.Title,
		DueAt:    b.StartAt.UTC(),
		Status:   "pending",
		Kind:     kindStudySchedule,
		Metadata: datatypes.JSON(meta),
	}
	return s.db.Create(&rem).Error
}

func (s *Service) resolveReminderEntityID(userID uuid.UUID, b TodayBlock) (uuid.UUID, error) {
	if b.EntityID != "" {
		if id, err := uuid.Parse(b.EntityID); err == nil && s.learningEntityExists(userID, id) {
			return id, nil
		}
	}
	return s.lookupLearningEntityID(userID, b.Track)
}

func (s *Service) learningEntityExists(userID, id uuid.UUID) bool {
	var n int64
	s.db.Model(&models.Entity{}).
		Where("id = ? AND user_id = ? AND domain = ? AND status = 'active'", id, userID, models.DomainLearning).
		Count(&n)
	return n > 0
}

func (s *Service) lookupLearningEntityID(userID uuid.UUID, track string) (uuid.UUID, error) {
	var ent models.Entity
	q := s.db.Where("user_id = ? AND domain = ? AND status = 'active'", userID, models.DomainLearning)
	switch track {
	case "english":
		q = q.Where("type = ? AND tags @> ?", "learning_course", `["english"]`)
	default:
		q = q.Where("type IN ?", []string{"learning_course", "learning_topic", "learning_pattern"})
	}
	if err := q.Order("updated_at DESC").First(&ent).Error; err != nil {
		return uuid.Nil, nil
	}
	return ent.ID, nil
}

func (s *Service) ensureSchedule(userID uuid.UUID) (*models.LearningSchedule, error) {
	var sched models.LearningSchedule
	err := s.db.Where("user_id = ?", userID).First(&sched).Error
	if err == nil {
		return &sched, nil
	}
	if err != gorm.ErrRecordNotFound {
		return nil, err
	}
	days, _ := json.Marshal([]int{1, 2, 3, 4, 5})
	sched = models.LearningSchedule{
		UserID:             userID,
		WorkStartHour:      8,
		WorkEndHour:        17,
		WorkDays:           datatypes.JSON(days),
		CommuteMinutes:     40,
		MorningCommuteTime: "07:15:00",
		EveningCommuteTime: "17:30:00",
		ToeicSessionTime:   "20:00:00",
		DsaCommuteMinutes:  25,
		EnglishCommuteMinutes: 20,
		ToeicDailyMinutes:  60,
		Timezone:           "Asia/Ho_Chi_Minh",
		PushEnabled:        true,
		DsaProgramStart:    time.Now(),
	}
	if err := s.db.Create(&sched).Error; err != nil {
		return nil, err
	}
	return &sched, nil
}

func buildTodayPlan(sched *models.LearningSchedule, now time.Time) *TodayPlan {
	workDays := parseWorkDays(sched.WorkDays)
	weekday := int(now.Weekday())
	if weekday == 0 {
		weekday = 7
	}
	isWorkDay := containsInt(workDays, weekday)

	plan := &TodayPlan{
		Date:      now.Format("2006-01-02"),
		Timezone:  sched.Timezone,
		IsWorkDay: isWorkDay,
	}

	if !isWorkDay {
		plan.Blocks = weekendBlocks(sched, now)
	} else {
		plan.Blocks = weekdayBlocks(sched, now)
	}
	for _, b := range plan.Blocks {
		plan.TotalMinutes += b.DurationMinutes
	}
	return plan
}

func enrichDSABlocks(plan *TodayPlan, dsa *DSADailyFocus) {
	for i := range plan.Blocks {
		if plan.Blocks[i].Track != "dsa" {
			continue
		}
		plan.Blocks[i].EntityID = dsa.PatternEntityID
		if plan.Blocks[i].Kind == blockDSAMorning {
			plan.Blocks[i].Title = fmt.Sprintf("Week %d · %s", dsa.ProgramWeek, dsa.PatternTitle)
			plan.Blocks[i].Subtitle = fmt.Sprintf("%s — %d problems today", dsaDayTypeLabel(dsa.DayType), dsa.TargetProblems)
			if len(dsa.Tasks) > 0 {
				plan.Blocks[i].CommuteTip = dsa.Tasks[0]
			}
		}
	}
}

func dsaDayTypeLabel(t string) string {
	switch t {
	case "learn":
		return "Learn day"
	case "practice":
		return "Practice day"
	case "review":
		return "Review day"
	case "mock", "weekend_mock", "mock_interview":
		return "Mock interview"
	case "timed_pair":
		return "Timed pair"
	case "morning_evening":
		return "Morning + evening"
	default:
		return "Study block"
	}
}

func weekdayBlocks(sched *models.LearningSchedule, now time.Time) []TodayBlock {
	morning := combineDateTime(now, sched.MorningCommuteTime)
	evening := combineDateTime(now, sched.EveningCommuteTime)
	toeic := combineDateTime(now, sched.ToeicSessionTime)

	return []TodayBlock{
		{
			ID:              blockDSAMorning,
			Kind:            blockDSAMorning,
			Track:           "dsa",
			Title:           "Metro DSA flash",
			Subtitle:        "1 pattern + spaced repetition on bus/metro",
			StartAt:         morning,
			DurationMinutes: sched.DsaCommuteMinutes,
			Mode:            "flash",
			EntityID:        dsaCourseID,
			CommuteTip:      "Open one DSA pattern, recall steps without notes, then check solution.",
		},
		{
			ID:              blockEnglishEvening,
			Kind:            blockEnglishEvening,
			Track:           "english",
			Title:           "Commute TOEIC vocab",
			Subtitle:        "Hardcore vocabulary — business + academic collocations",
			StartAt:         evening,
			DurationMinutes: sched.EnglishCommuteMinutes,
			Mode:            "vocab",
			EntityID:        englishCourseID,
			CommuteTip:      "10 words: definition → example sentence → antonym. No scrolling feeds.",
		},
		{
			ID:              blockTOEICEvening,
			Kind:            blockTOEICEvening,
			Track:           "english",
			Title:           "TOEIC deep session",
			Subtitle:        "Grammar traps + listening/reading rotation",
			StartAt:         toeic,
			DurationMinutes: sched.ToeicDailyMinutes,
			Mode:            "deep",
			EntityID:        englishCourseID,
			CommuteTip:      "Rotate: Part 5 grammar → Part 3 listening → Part 7 inference.",
		},
	}
}

func weekendBlocks(sched *models.LearningSchedule, now time.Time) []TodayBlock {
	morning := combineDateTime(now, "09:00:00")
	afternoon := combineDateTime(now, "15:00:00")
	return []TodayBlock{
		{
			ID: blockDSAMorning, Kind: blockDSAMorning, Track: "dsa",
			Title: "Weekend DSA block", Subtitle: "2 patterns + mock problem",
			StartAt: morning, DurationMinutes: 45, Mode: "deep", EntityID: dsaCourseID,
		},
		{
			ID: blockTOEICEvening, Kind: blockTOEICEvening, Track: "english",
			Title: "Weekend TOEIC marathon", Subtitle: "Full skill rotation",
			StartAt: afternoon, DurationMinutes: sched.ToeicDailyMinutes, Mode: "deep", EntityID: englishCourseID,
		},
	}
}

func combineDateTime(day time.Time, timeStr string) time.Time {
	t := normalizeTime(timeStr)
	if len(t) == 5 {
		t += ":00"
	}
	parsed, err := time.Parse("15:04:05", t)
	if err != nil {
		parsed, _ = time.Parse("15:04", t)
	}
	return time.Date(day.Year(), day.Month(), day.Day(), parsed.Hour(), parsed.Minute(), 0, 0, day.Location())
}

func scheduleToDTO(s *models.LearningSchedule) *ScheduleDTO {
	return &ScheduleDTO{
		WorkStartHour:         s.WorkStartHour,
		WorkEndHour:           s.WorkEndHour,
		WorkDays:              parseWorkDays(s.WorkDays),
		CommuteMinutes:        s.CommuteMinutes,
		MorningCommuteTime:    trimSeconds(s.MorningCommuteTime),
		EveningCommuteTime:    trimSeconds(s.EveningCommuteTime),
		ToeicSessionTime:      trimSeconds(s.ToeicSessionTime),
		DsaCommuteMinutes:     s.DsaCommuteMinutes,
		EnglishCommuteMinutes: s.EnglishCommuteMinutes,
		ToeicDailyMinutes:     s.ToeicDailyMinutes,
		Timezone:              s.Timezone,
		PushEnabled:           s.PushEnabled,
	}
}

func parseWorkDays(raw datatypes.JSON) []int {
	var days []int
	_ = json.Unmarshal(raw, &days)
	if len(days) == 0 {
		return []int{1, 2, 3, 4, 5}
	}
	return days
}

func defaultWorkDays(in []int) []int {
	if len(in) == 0 {
		return []int{1, 2, 3, 4, 5}
	}
	return in
}

func loadLocation(tz string) *time.Location {
	loc, err := time.LoadLocation(tz)
	if err != nil {
		return time.FixedZone("VN", 7*3600)
	}
	return loc
}

func normalizeTime(s string) string {
	s = trimSeconds(s)
	if len(s) == 5 {
		return s
	}
	return s
}

func trimSeconds(s string) string {
	if len(s) >= 8 && s[2] == ':' && s[5] == ':' {
		return s[:5]
	}
	return s
}

func clamp(v, min, max, fallback int) int {
	if v == 0 {
		return fallback
	}
	if v < min {
		return min
	}
	if v > max {
		return max
	}
	return v
}

func containsInt(list []int, v int) bool {
	for _, x := range list {
		if x == v {
			return true
		}
	}
	return false
}
