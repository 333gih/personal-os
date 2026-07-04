package modules

import (
	"encoding/json"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/pkg/plugin"
	"gorm.io/gorm"
)

const (
	TierCore   = "core"
	TierDomain = "domain"

	minEnabledDomains = 1
	maxEnabledDomains = 6
	maxPinnedTabs     = 3
)

// Catalog holds compile-time module descriptors.
type Catalog struct {
	modules     []plugin.Module
	byID        map[string]plugin.Module
	byRoute     map[string]string
	defaultPins map[string]*int
}

func NewCatalog() *Catalog {
	c := &Catalog{
		byID:        make(map[string]plugin.Module),
		byRoute:     make(map[string]string),
		defaultPins: make(map[string]*int),
	}
	c.registerDefaults()
	return c
}

func (c *Catalog) Register(m plugin.Module, defaultPin *int) {
	c.modules = append(c.modules, m)
	c.byID[m.ID()] = m
	if defaultPin != nil {
		c.defaultPins[m.ID()] = defaultPin
	}
	for _, prefix := range m.RoutePrefixes() {
		c.byRoute[normalizePrefix(prefix)] = m.ID()
	}
}

func (c *Catalog) All() []plugin.Module {
	out := make([]plugin.Module, len(c.modules))
	copy(out, c.modules)
	return out
}

func (c *Catalog) Get(id string) (plugin.Module, bool) {
	m, ok := c.byID[id]
	return m, ok
}

func (c *Catalog) ModuleForPath(path string) string {
	path = normalizePrefix(path)
	best := ""
	bestLen := 0
	for prefix, id := range c.byRoute {
		if strings.HasPrefix(path, prefix) && len(prefix) > bestLen {
			best = id
			bestLen = len(prefix)
		}
	}
	return best
}

func normalizePrefix(p string) string {
	p = strings.TrimSpace(p)
	if p == "" {
		return ""
	}
	if !strings.HasPrefix(p, "/") {
		p = "/" + p
	}
	return strings.TrimSuffix(p, "/")
}

type baseModule struct {
	id              string
	label           string
	description     string
	icon            string
	tier            string
	domain          string
	entityTypes     []string
	defaultEnabled  bool
	required        bool
	dependsOn       []string
	routePrefixes   []string
	navHref         string
	workers         []plugin.WorkerSpec
	aiPersona       string
	integrationSlots []string
}

func (m baseModule) Name() string { return m.id }
func (m baseModule) ID() string                { return m.id }
func (m baseModule) Label() string             { return m.label }
func (m baseModule) Description() string       { return m.description }
func (m baseModule) Icon() string              { return m.icon }
func (m baseModule) Tier() string              { return m.tier }
func (m baseModule) Domain() string            { return m.domain }
func (m baseModule) EntityTypes() []string     { return m.entityTypes }
func (m baseModule) DefaultEnabled() bool      { return m.defaultEnabled }
func (m baseModule) Required() bool            { return m.required }
func (m baseModule) DependsOn() []string       { return m.dependsOn }
func (m baseModule) RoutePrefixes() []string   { return m.routePrefixes }
func (m baseModule) NavHref() string           { return m.navHref }
func (m baseModule) Workers() []plugin.WorkerSpec { return m.workers }
func (m baseModule) AIPersona() string         { return m.aiPersona }
func (m baseModule) IntegrationSlots() []string { return m.integrationSlots }
func (m baseModule) ConfigSchema() json.RawMessage {
	return json.RawMessage(`{}`)
}
func (m baseModule) RegisterRoutes(_ *gin.RouterGroup) {}
func (m baseModule) Migrate(_ *gorm.DB) error          { return nil }

func intPtr(v int) *int { return &v }

func (c *Catalog) registerDefaults() {
	c.Register(baseModule{
		id: "core", label: "Core", description: "Auth, dashboard, files, and AI gateway",
		icon: "home", tier: TierCore, domain: "", defaultEnabled: true, required: true,
		routePrefixes: []string{"/dashboard", "/files", "/ai", "/reminders", "/relationships"},
		navHref: "/dashboard", aiPersona: "general",
	}, nil)
	c.Register(baseModule{
		id: "inbox", label: "Inbox", description: "Quick capture for notes, links, and ideas",
		icon: "inbox", tier: TierCore, domain: models.DomainInbox, defaultEnabled: true, required: true,
		routePrefixes: []string{}, navHref: "/inbox", aiPersona: "general",
		entityTypes: []string{models.TypeInboxNote, models.TypeInboxText, models.TypeInboxURL},
	}, nil)
	c.Register(baseModule{
		id: "search", label: "Search", description: "Hybrid full-text and semantic search",
		icon: "search", tier: TierCore, domain: "", defaultEnabled: true, required: true,
		routePrefixes: []string{"/search"}, navHref: "/search", aiPersona: "general",
	}, nil)
	c.Register(baseModule{
		id: models.ModuleWork, label: "Work", description: "Career path, CV, job scout, and work import",
		icon: "briefcase", tier: TierDomain, domain: models.DomainWork, defaultEnabled: true,
		routePrefixes: []string{"/cv", "/jobs", "/work"},
		navHref: "/work", aiPersona: "work_coach",
		integrationSlots: []string{"calendar"},
		workers: []plugin.WorkerSpec{{Name: "jobscout_daily_scan", Interval: "15m"}},
		entityTypes: []string{models.TypeWorkProject, models.TypeWorkDesignDoc, models.TypeWorkEmployer},
	}, intPtr(1))
	c.Register(baseModule{
		id: models.ModuleLearning, label: "Learning", description: "Study schedule, DSA program, and AI coach",
		icon: "book-open", tier: TierDomain, domain: models.DomainLearning, defaultEnabled: true,
		routePrefixes: []string{"/learning"},
		navHref: "/learning", aiPersona: "learning_coach",
		integrationSlots: []string{"calendar"},
		workers: []plugin.WorkerSpec{{Name: "studylearning_worker", Interval: "2m"}},
		entityTypes: []string{models.TypeCourse, models.TypeTopic, models.TypeLearningNote},
	}, intPtr(2))
	c.Register(baseModule{
		id: models.ModuleStartup, label: "Startup", description: "Ideas, business models, and startup notes",
		icon: "rocket", tier: TierDomain, domain: models.DomainStartup, defaultEnabled: true,
		routePrefixes: []string{"/startup"},
		navHref: "/startup", aiPersona: "startup_advisor",
		entityTypes: []string{models.TypeStartupIdea, models.TypeBusinessModel},
	}, intPtr(4))
	c.Register(baseModule{
		id: models.ModuleEntertainment, label: "Entertainment", description: "Reading progress and Story Tracker sync",
		icon: "gamepad-2", tier: TierDomain, domain: models.DomainEntertainment, defaultEnabled: true,
		routePrefixes: []string{"/reading-progress"},
		navHref: "/entertainment",
		integrationSlots: []string{"story_tracker"},
	}, intPtr(5))
	c.Register(baseModule{
		id: models.ModuleGoals, label: "Goals", description: "Habits, targets, and milestones",
		icon: "target", tier: TierDomain, domain: models.DomainGoal, defaultEnabled: true,
		routePrefixes: []string{"/goals"},
		navHref: "/goals", aiPersona: "goal_reflector",
		entityTypes: []string{models.TypeGoalHabit, models.TypeGoalTarget, models.TypeGoalMilestone},
	}, intPtr(6))
	c.Register(baseModule{
		id: models.ModuleJournal, label: "Journal", description: "Daily logs and reflections",
		icon: "book", tier: TierDomain, domain: models.DomainJournal, defaultEnabled: false,
		routePrefixes: []string{},
		navHref: "/journal", aiPersona: "journal_companion",
		entityTypes: []string{models.TypeJournalEntry, models.TypeJournalReflection},
	}, nil)
}
