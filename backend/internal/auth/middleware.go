package auth

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/pkg/response"
)

const UserIDKey = "user_id"

func Middleware(s *Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		if header == "" {
			response.Unauthorized(c, "missing authorization header")
			c.Abort()
			return
		}

		parts := strings.SplitN(header, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
			response.Unauthorized(c, "invalid authorization header")
			c.Abort()
			return
		}

		userID, err := s.ParseToken(parts[1])
		if err != nil {
			response.Unauthorized(c, "invalid token")
			c.Abort()
			return
		}

		c.Set(UserIDKey, userID)
		c.Next()
	}
}

func GetUserID(c *gin.Context) uuid.UUID {
	v, _ := c.Get(UserIDKey)
	id, _ := v.(uuid.UUID)
	return id
}
