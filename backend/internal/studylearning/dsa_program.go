package studylearning

import (
	"fmt"
	"time"

	"github.com/google/uuid"
)

type DSADailyFocus struct {
	ProgramWeek      int              `json:"program_week"`
	ProgramDay       int              `json:"program_day"`
	Weekday          int              `json:"weekday"`
	Phase            string           `json:"phase"`
	DayType          string           `json:"day_type"`
	PatternOrder     int              `json:"pattern_order"`
	PatternTitle     string           `json:"pattern_title"`
	PatternEntityID  string           `json:"pattern_entity_id"`
	Tasks            []string         `json:"tasks"`
	TargetProblems   int              `json:"target_problems"`
	CumulativeTarget int              `json:"cumulative_target"`
	SuggestedProblems []string        `json:"suggested_problems,omitempty"`
	Benchmarks       DSABenchmarks    `json:"benchmarks"`
	MockToday        bool             `json:"mock_today"`
}

type DSABenchmarks struct {
	EasyMinutes   int `json:"easy_minutes"`
	MediumMinutes int `json:"medium_minutes"`
	HardMinutes   int `json:"hard_minutes"`
}

var patternEntityByOrder = map[int]string{
	1:  "c000000c-0001-4001-8001-000000000003",
	2:  "c000000c-0001-4001-8001-000000000004",
	3:  "c000000c-0001-4001-8001-000000000005",
	4:  "c000000c-0001-4001-8001-000000000006",
	5:  "c000000c-0001-4001-8001-000000000007",
	6:  "c000000c-0001-4001-8001-000000000008",
	7:  "c000000c-0001-4001-8001-000000000009",
	8:  "c000000c-0001-4001-8001-000000000010",
	9:  "c000000c-0001-4001-8001-000000000011",
	10: "c000000c-0001-4001-8001-000000000012",
	11: "c000000c-0001-4001-8001-000000000013",
	12: "c000000c-0001-4001-8001-000000000014",
	13: "c000000c-0001-4001-8001-000000000015",
	14: "c000000c-0001-4001-8001-000000000016",
	15: "c000000c-0001-4001-8001-000000000017",
	16: "c000000c-0001-4001-8001-000000000018",
	17: "c000000c-0001-4001-8001-000000000019",
	18: "c000000c-0001-4001-8001-000000000020",
	19: "c000000c-0001-4001-8001-000000000021",
	20: "c000000c-0001-4001-8001-000000000022",
}

var weekPatternOrders = map[int][]int{
	1:  {1, 3},
	2:  {2, 4, 5},
	3:  {6, 7},
	4:  {8, 9, 10},
	5:  {11, 13, 12},
	6:  {14, 15, 16},
	7:  {17},
	8:  {18, 19, 20},
}

func (s *Service) DSADailyFocus(userID uuid.UUID) (*DSADailyFocus, error) {
	s.ensureCurriculum(userID)
	sched, err := s.ensureSchedule(userID)
	if err != nil {
		return nil, err
	}
	loc := loadLocation(sched.Timezone)
	now := time.Now().In(loc)

	start := sched.DsaProgramStart
	if start.IsZero() {
		start = time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, loc)
	} else {
		start = time.Date(start.Year(), start.Month(), start.Day(), 0, 0, 0, 0, loc)
	}

	dayOffset := int(now.Sub(start).Hours() / 24)
	if dayOffset < 0 {
		dayOffset = 0
	}
	programDay := dayOffset + 1
	programWeek := dayOffset/7 + 1
	if programWeek > 10 {
		programWeek = 10
	}

	weekday := int(now.Weekday())
	if weekday == 0 {
		weekday = 7
	}

	phase := dsaPhase(programWeek)
	dayType := dsaDayType(programWeek, weekday)
	patternOrder := dsaPatternOrder(programWeek, programDay)
	entityID := patternEntityByOrder[patternOrder]

	title, problems := s.patternInfo(userID, entityID)
	tasks := dsaTasks(dayType, phase, patternOrder)
	target, cumulative := dsaProblemTargets(programWeek, dayType)

	return &DSADailyFocus{
		ProgramWeek:       programWeek,
		ProgramDay:        programDay,
		Weekday:           weekday,
		Phase:             phase,
		DayType:           dayType,
		PatternOrder:      patternOrder,
		PatternTitle:      title,
		PatternEntityID:   entityID,
		Tasks:             tasks,
		TargetProblems:    target,
		CumulativeTarget:  cumulative,
		SuggestedProblems: problems,
		Benchmarks:        DSABenchmarks{EasyMinutes: 8, MediumMinutes: 20, HardMinutes: 35},
		MockToday:         dayType == "mock" || dayType == "mock_interview" || dayType == "weekend_mock",
	}, nil
}

func (s *Service) patternInfo(userID uuid.UUID, entityID string) (string, []string) {
	eid, err := uuid.Parse(entityID)
	if err != nil {
		return "DSA Pattern", nil
	}
	ent, err := s.learning.GetEntity(userID, eid)
	if err != nil {
		return "DSA Pattern", nil
	}
	var probs []string
	if raw, ok := ent.Metadata["problems"].([]interface{}); ok {
		for _, p := range raw {
			if str, ok := p.(string); ok {
				probs = append(probs, str)
			}
		}
	}
	if len(probs) > 4 {
		probs = probs[:4]
	}
	return ent.Title, probs
}

func dsaPhase(week int) string {
	switch {
	case week <= 2:
		return "foundation"
	case week <= 5:
		return "core"
	case week <= 8:
		return "advanced"
	default:
		return "mock_mastery"
	}
}

func dsaDayType(week, weekday int) string {
	if week >= 9 {
		if weekday <= 4 {
			return "timed_pair"
		}
		return "mock_interview"
	}
	if week >= 6 {
		if weekday >= 6 {
			return "weekend_mock"
		}
		return "morning_evening"
	}
	if week >= 3 {
		if weekday >= 6 {
			return "weekend_mock"
		}
		return "learn_plus_review"
	}
	switch weekday {
	case 1, 2, 3:
		return "learn"
	case 4, 5:
		return "practice"
	case 6:
		return "review"
	default:
		return "mock"
	}
}

func dsaPatternOrder(week, programDay int) int {
	if week >= 9 {
		return (programDay % 20) + 1
	}
	patterns := weekPatternOrders[week]
	if len(patterns) == 0 {
		return (programDay % 20) + 1
	}
	return patterns[(programDay-1)%len(patterns)]
}

func dsaTasks(dayType, phase string, patternOrder int) []string {
	switch dayType {
	case "learn":
		return []string{
			fmt.Sprintf("Read pattern #%d theory + code template (5 min)", patternOrder),
			"Recall recognition signals without notes (2 min)",
			"Solve 3 Easy problems — target <8 min each",
		}
	case "practice":
		return []string{
			fmt.Sprintf("Pattern #%d: identify approach before coding", patternOrder),
			"Solve 3 Medium problems — target <20 min each",
			"Log mistakes in Learning notes",
		}
	case "review":
		return []string{
			"Re-solve 2 problems you failed this week",
			"Rewrite template from memory (<5 min)",
			"Verbalize time/space complexity for each",
		}
	case "mock", "weekend_mock", "mock_interview":
		return []string{
			"STAR mock: UNDERSTAND → EXAMPLES → APPROACH → CODE → TEST → COMPLEXITY",
			"Timed session: 2 problems in 45 min (no hints)",
			"Score pattern recognition (<60s) and edge cases",
		}
	case "timed_pair":
		return []string{
			"Random 2 problems from any learned pattern",
			"45-minute timer, blank editor",
			"Review against benchmark: Medium <20 min",
		}
	case "morning_evening":
		return []string{
			fmt.Sprintf("Morning (30 min): 1 %s-pattern problem", phase),
			"Evening (60 min): 1 Hard OR 2 Medium revisit",
			"Track cumulative count toward week target",
		}
	case "learn_plus_review":
		return []string{
			fmt.Sprintf("Study pattern #%d definition + 4 problems", patternOrder),
			"2 new problems + 1 spaced-repetition review",
			"Note recognition signal that triggered the pattern",
		}
	default:
		return []string{"Open today's pattern and solve 2 problems"}
	}
}

func dsaProblemTargets(week int, dayType string) (daily, cumulative int) {
	switch {
	case week <= 2:
		daily = 3
		cumulative = 25 + (week-1)*15
	case week <= 5:
		daily = 4
		cumulative = 55 + (week-3)*18
	case week <= 8:
		daily = 4
		cumulative = 110 + (week-6)*20
	default:
		daily = 2
		cumulative = 160 + (week-9)*10
	}
	if dayType == "mock" || dayType == "weekend_mock" || dayType == "mock_interview" {
		daily = 2
	}
	return daily, cumulative
}
