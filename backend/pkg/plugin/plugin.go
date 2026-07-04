// Package plugin defines the extension interface for Personal OS modules.
// MVP uses compile-time catalog registration; no runtime plugin loading.
package plugin

import (
	"encoding/json"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Plugin is the base interface domain modules implement.
type Plugin interface {
	Name() string
	Domain() string
	EntityTypes() []string
	RegisterRoutes(r *gin.RouterGroup)
	Migrate(db *gorm.DB) error
}

// WorkerSpec describes a background worker owned by a module.
type WorkerSpec struct {
	Name     string `json:"name"`
	Interval string `json:"interval,omitempty"`
}

// Module extends Plugin with catalog metadata for user-facing module selection.
type Module interface {
	Plugin
	ID() string
	Label() string
	Description() string
	Icon() string
	Tier() string // "core" | "domain"
	DefaultEnabled() bool
	Required() bool
	DependsOn() []string
	RoutePrefixes() []string
	NavHref() string
	Workers() []WorkerSpec
	AIPersona() string
	IntegrationSlots() []string
	ConfigSchema() json.RawMessage
}

// Registry holds registered plugins (future use).
type Registry struct {
	plugins []Plugin
}

func NewRegistry() *Registry {
	return &Registry{}
}

func (r *Registry) Register(p Plugin) {
	r.plugins = append(r.plugins, p)
}

func (r *Registry) All() []Plugin {
	return r.plugins
}

func (r *Registry) RegisterRoutes(api *gin.RouterGroup) {
	for _, p := range r.plugins {
		p.RegisterRoutes(api.Group("/plugins/" + p.Name()))
	}
}

func (r *Registry) MigrateAll(db *gorm.DB) error {
	for _, p := range r.plugins {
		if err := p.Migrate(db); err != nil {
			return err
		}
	}
	return nil
}
