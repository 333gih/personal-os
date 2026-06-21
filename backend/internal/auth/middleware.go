package auth

import (
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/pkg/response"
)

const UserIDKey = "user_id"

func Middleware(s *Service) gin.HandlerFunc {
	if s.UsesFashAuth() {
		return fashMiddleware(s)
	}
	return localMiddleware(s)
}

func localMiddleware(s *Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		token, ok := bearerToken(c)
		if !ok {
			response.Unauthorized(c, "missing authorization header")
			c.Abort()
			return
		}

		userID, err := s.ParseToken(token)
		if err != nil {
			response.Unauthorized(c, "invalid token")
			c.Abort()
			return
		}

		c.Set(UserIDKey, userID)
		c.Next()
	}
}

func fashMiddleware(s *Service) gin.HandlerFunc {
	return func(c *gin.Context) {
		token, ok := bearerToken(c)
		if !ok {
			response.Unauthorized(c, "missing authorization header")
			c.Abort()
			return
		}

		userID, email, err := s.ParseFashToken(token)
		if err != nil {
			response.Unauthorized(c, "invalid token")
			c.Abort()
			return
		}

		if err := s.EnsureUserFromFash(userID, email); err != nil {
			response.InternalError(c, "user sync failed")
			c.Abort()
			return
		}

		s.SyncCareerForUser(userID, email)

		c.Set(UserIDKey, userID)
		c.Next()
	}
}

func bearerToken(c *gin.Context) (string, bool) {
	header := c.GetHeader("Authorization")
	if header == "" {
		return "", false
	}
	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return "", false
	}
	token := strings.TrimSpace(parts[1])
	return token, token != ""
}

func GetUserID(c *gin.Context) uuid.UUID {
	v, _ := c.Get(UserIDKey)
	id, _ := v.(uuid.UUID)
	return id
}
