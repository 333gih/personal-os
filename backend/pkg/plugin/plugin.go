// Package plugin defines the extension interface for future Personal OS plugins.
// MVP does not load plugins at runtime; this contract enables future extensibility.
package plugin

import (
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// Plugin is the interface future domain plugins will implement.
type Plugin interface {
	Name() string
	Domain() string
	EntityTypes() []string
	RegisterRoutes(r *gin.RouterGroup)
	Migrate(db *gorm.DB) error
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
