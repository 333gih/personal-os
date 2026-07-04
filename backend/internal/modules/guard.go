package modules

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/pkg/response"
)

func (s *Service) GuardMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		reqPath := c.Request.URL.Path
		if idx := strings.Index(reqPath, "/api/v1"); idx >= 0 {
			reqPath = reqPath[idx+len("/api/v1"):]
		}

		for _, skip := range []string{"/modules", "/auth", "/health", "/integrations", "/entities"} {
			if strings.HasPrefix(reqPath, skip) {
				c.Next()
				return
			}
		}

		moduleID := s.catalog.ModuleForPath(reqPath)
		if moduleID == "" {
			c.Next()
			return
		}

		userID := auth.GetUserID(c)
		if userID == uuid.Nil {
			c.Next()
			return
		}

		if !s.IsEnabledForUser(userID, moduleID) {
			response.Forbidden(c, "module disabled: "+moduleID)
			c.Abort()
			return
		}
		c.Next()
	}
}
