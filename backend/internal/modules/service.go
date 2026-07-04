package modules

import (
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/pkg/plugin"
	"gorm.io/gorm"
)

var (
	ErrModuleRequired     = errors.New("module is required and cannot be disabled")
	ErrMinDomains         = fmt.Errorf("at least %d domain module must stay enabled", minEnabledDomains)
	ErrMaxDomains         = fmt.Errorf("at most %d domain modules can be enabled", maxEnabledDomains)
	ErrUnknownModule      = errors.New("unknown module")
	ErrDependencyDisabled = errors.New("dependency module is disabled")
)

type CatalogEntry struct {
	ID               string              `json:"id"`
	Label            string              `json:"label"`
	Description      string              `json:"description"`
	Icon             string              `json:"icon"`
	Tier             string              `json:"tier"`
	Domain           string              `json:"domain,omitempty"`
	DefaultEnabled   bool                `json:"default_enabled"`
	Required         bool                `json:"required"`
	DependsOn        []string            `json:"depends_on,omitempty"`
	NavHref          string              `json:"nav_href,omitempty"`
	AIPersona        string              `json:"ai_persona,omitempty"`
	IntegrationSlots []string            `json:"integration_slots,omitempty"`
	Workers          []plugin.WorkerSpec `json:"workers,omitempty"`
	EntityTypes      []string            `json:"entity_types,omitempty"`
}

type PrefDTO struct {
	ModuleID  string         `json:"module_id"`
	Enabled   bool           `json:"enabled"`
	PinOrder  *int           `json:"pin_order,omitempty"`
	Config    map[string]any `json:"config"`
	UpdatedAt time.Time      `json:"updated_at"`
}

type NavManifest struct {
	Tabs   []string `json:"tabs"`
	Drawer []string `json:"drawer"`
}

type ListResponse struct {
	Catalog []CatalogEntry `json:"catalog"`
	Prefs   []PrefDTO      `json:"prefs"`
	Nav     NavManifest    `json:"nav"`
	Rules   RulesDTO       `json:"rules"`
}

type RulesDTO struct {
	Required          []string `json:"required"`
	MinEnabledDomains int      `json:"min_enabled_domains"`
	MaxEnabledDomains int      `json:"max_enabled_domains"`
	MaxPinnedTabs     int      `json:"max_pinned_tabs"`
}

type UpdatePrefInput struct {
	ModuleID string         `json:"module_id" binding:"required"`
	Enabled  *bool          `json:"enabled"`
	PinOrder *int           `json:"pin_order"`
	Config   map[string]any `json:"config"`
}

type UpdateRequest struct {
	Prefs []UpdatePrefInput `json:"prefs" binding:"required,dive"`
}

type Service struct {
	db      *gorm.DB
	catalog *Catalog
}

func NewService(db *gorm.DB, catalog *Catalog) *Service {
	return &Service{db: db, catalog: catalog}
}

func (s *Service) List(userID uuid.UUID) (*ListResponse, error) {
	if err := s.EnsureDefaults(userID); err != nil {
		return nil, err
	}
	prefs, err := s.loadPrefs(userID)
	if err != nil {
		return nil, err
	}
	return s.buildListResponse(prefs), nil
}

func (s *Service) EnsureDefaults(userID uuid.UUID) error {
	var count int64
	if err := s.db.Model(&models.UserModulePref{}).Where("user_id = ?", userID).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	now := time.Now().UTC()
	rows := make([]models.UserModulePref, 0, len(s.catalog.modules))
	for _, m := range s.catalog.All() {
		pin := s.catalog.defaultPins[m.ID()]
		rows = append(rows, models.UserModulePref{
			UserID:    userID,
			ModuleID:  m.ID(),
			Enabled:   m.DefaultEnabled(),
			PinOrder:  pin,
			Config:    map[string]any{},
			UpdatedAt: now,
		})
	}
	return s.db.Create(&rows).Error
}

func (s *Service) Update(userID uuid.UUID, req UpdateRequest) (*ListResponse, error) {
	if err := s.EnsureDefaults(userID); err != nil {
		return nil, err
	}
	prefs, err := s.loadPrefMap(userID)
	if err != nil {
		return nil, err
	}

	for _, in := range req.Prefs {
		m, ok := s.catalog.Get(in.ModuleID)
		if !ok {
			return nil, ErrUnknownModule
		}
		row, ok := prefs[in.ModuleID]
		if !ok {
			return nil, ErrUnknownModule
		}
		if in.Enabled != nil {
			if m.Required() && !*in.Enabled {
				return nil, ErrModuleRequired
			}
			row.Enabled = *in.Enabled
		}
		if in.PinOrder != nil {
			row.PinOrder = in.PinOrder
		}
		if in.Config != nil {
			row.Config = in.Config
		}
		row.UpdatedAt = time.Now().UTC()
		prefs[in.ModuleID] = row
	}

	if err := s.validatePrefs(prefs); err != nil {
		return nil, err
	}

	for _, row := range prefs {
		if err := s.db.Save(&row).Error; err != nil {
			return nil, err
		}
	}

	listPrefs := make([]models.UserModulePref, 0, len(prefs))
	for _, row := range prefs {
		listPrefs = append(listPrefs, row)
	}
	return s.buildListResponse(listPrefs), nil
}

func (s *Service) validatePrefs(prefs map[string]models.UserModulePref) error {
	enabledDomains := 0
	for _, m := range s.catalog.All() {
		row, ok := prefs[m.ID()]
		if !ok {
			continue
		}
		if m.Tier() == TierDomain && row.Enabled {
			enabledDomains++
		}
		for _, dep := range m.DependsOn() {
			depRow, ok := prefs[dep]
			if ok && row.Enabled && !depRow.Enabled {
				return fmt.Errorf("%w: %s requires %s", ErrDependencyDisabled, m.ID(), dep)
			}
		}
	}
	if enabledDomains < minEnabledDomains {
		return ErrMinDomains
	}
	if enabledDomains > maxEnabledDomains {
		return ErrMaxDomains
	}
	return nil
}

func (s *Service) IsEnabledForUser(userID uuid.UUID, moduleID string) bool {
	_ = s.EnsureDefaults(userID)
	m, ok := s.catalog.Get(moduleID)
	if !ok {
		return false
	}
	if m.Required() {
		return true
	}
	var row models.UserModulePref
	err := s.db.Where("user_id = ? AND module_id = ?", userID, moduleID).First(&row).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return m.DefaultEnabled()
	}
	if err != nil {
		return m.DefaultEnabled()
	}
	return row.Enabled
}

func (s *Service) EnabledDomains(userID uuid.UUID) []string {
	_ = s.EnsureDefaults(userID)
	prefs, err := s.loadPrefs(userID)
	if err != nil {
		return nil
	}
	out := make([]string, 0)
	for _, p := range prefs {
		if !p.Enabled {
			continue
		}
		m, ok := s.catalog.Get(p.ModuleID)
		if !ok || m.Tier() != TierDomain {
			continue
		}
		if d := m.Domain(); d != "" {
			out = append(out, d)
		}
	}
	return out
}

func (s *Service) ModuleConfigBool(userID uuid.UUID, moduleID, key string) bool {
	var row models.UserModulePref
	if err := s.db.Where("user_id = ? AND module_id = ?", userID, moduleID).First(&row).Error; err != nil {
		return false
	}
	if row.Config == nil {
		return false
	}
	v, ok := row.Config[key]
	if !ok {
		return false
	}
	b, ok := v.(bool)
	return ok && b
}

func (s *Service) loadPrefs(userID uuid.UUID) ([]models.UserModulePref, error) {
	var rows []models.UserModulePref
	if err := s.db.Where("user_id = ?", userID).Find(&rows).Error; err != nil {
		return nil, err
	}
	return rows, nil
}

func (s *Service) loadPrefMap(userID uuid.UUID) (map[string]models.UserModulePref, error) {
	rows, err := s.loadPrefs(userID)
	if err != nil {
		return nil, err
	}
	out := make(map[string]models.UserModulePref, len(rows))
	for _, row := range rows {
		out[row.ModuleID] = row
	}
	return out, nil
}

func (s *Service) buildListResponse(prefs []models.UserModulePref) *ListResponse {
	prefByID := make(map[string]models.UserModulePref, len(prefs))
	for _, p := range prefs {
		prefByID[p.ModuleID] = p
	}

	catalog := make([]CatalogEntry, 0, len(s.catalog.modules))
	required := make([]string, 0)
	for _, m := range s.catalog.All() {
		if m.Required() {
			required = append(required, m.ID())
		}
		catalog = append(catalog, CatalogEntry{
			ID:               m.ID(),
			Label:            m.Label(),
			Description:      m.Description(),
			Icon:             m.Icon(),
			Tier:             m.Tier(),
			Domain:           m.Domain(),
			DefaultEnabled:   m.DefaultEnabled(),
			Required:         m.Required(),
			DependsOn:        m.DependsOn(),
			NavHref:          m.NavHref(),
			AIPersona:        m.AIPersona(),
			IntegrationSlots: m.IntegrationSlots(),
			Workers:          m.Workers(),
			EntityTypes:      m.EntityTypes(),
		})
	}

	prefDTOs := make([]PrefDTO, 0, len(prefs))
	for _, p := range prefs {
		cfg := map[string]any{}
		for k, v := range p.Config {
			cfg[k] = v
		}
		prefDTOs = append(prefDTOs, PrefDTO{
			ModuleID:  p.ModuleID,
			Enabled:   p.Enabled,
			PinOrder:  p.PinOrder,
			Config:    cfg,
			UpdatedAt: p.UpdatedAt,
		})
	}
	sort.Slice(prefDTOs, func(i, j int) bool {
		return prefDTOs[i].ModuleID < prefDTOs[j].ModuleID
	})

	return &ListResponse{
		Catalog: catalog,
		Prefs:   prefDTOs,
		Nav:     buildNavManifest(s.catalog, prefByID),
		Rules: RulesDTO{
			Required:          required,
			MinEnabledDomains: minEnabledDomains,
			MaxEnabledDomains: maxEnabledDomains,
			MaxPinnedTabs:     maxPinnedTabs,
		},
	}
}

func buildNavManifest(catalog *Catalog, prefs map[string]models.UserModulePref) NavManifest {
	type pinned struct {
		id   string
		href string
		order int
	}
	pinnedItems := make([]pinned, 0)
	drawer := make([]string, 0)

	for _, m := range catalog.All() {
		if m.Tier() != TierDomain {
			continue
		}
		p, ok := prefs[m.ID()]
		if !ok || !p.Enabled {
			continue
		}
		href := navIDFromHref(m.NavHref())
		if p.PinOrder != nil && *p.PinOrder >= 0 {
			pinnedItems = append(pinnedItems, pinned{id: href, href: m.NavHref(), order: *p.PinOrder})
		} else {
			drawer = append(drawer, href)
		}
	}

	sort.Slice(pinnedItems, func(i, j int) bool {
		return pinnedItems[i].order < pinnedItems[j].order
	})

	tabs := []string{"dashboard"}
	for i, item := range pinnedItems {
		if i >= maxPinnedTabs {
			drawer = append(drawer, item.id)
			continue
		}
		tabs = append(tabs, item.id)
	}
	tabs = append(tabs, "search")

	if len(drawer) == 0 {
		drawer = append(drawer, "inbox", "settings")
	} else {
		drawer = append(drawer, "inbox", "settings")
	}

	return NavManifest{Tabs: tabs, Drawer: drawer}
}

func navIDFromHref(href string) string {
	href = strings.TrimPrefix(href, "/")
	if href == "" {
		return "dashboard"
	}
	return href
}
