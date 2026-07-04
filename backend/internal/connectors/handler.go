package connectors

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/internal/connectors/calendar"
	"github.com/personal-os/backend/pkg/response"
)

type Handler struct {
	calendar *calendar.Service
}

func NewHandler(cal *calendar.Service) *Handler {
	return &Handler{calendar: cal}
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	r.GET("", h.List)
	r.GET("/calendar/connect", h.CalendarConnect)
	r.DELETE("/calendar", h.CalendarDisconnect)
	r.POST("/calendar/sync", h.CalendarSync)
}

func (h *Handler) RegisterPublicRoutes(r *gin.RouterGroup) {
	r.GET("/calendar/callback", h.CalendarCallback)
}

func (h *Handler) List(c *gin.Context) {
	userID := auth.GetUserID(c)
	ctx := c.Request.Context()
	items := []IntegrationStatus{{
		Provider:  calendar.ProviderGoogle,
		Label:     "Google Calendar",
		Connected: h.calendar.Connected(ctx, userID),
	}}
	row := h.calendar.Status(ctx, userID)
	if row.Scopes != "" {
		items[0].Scopes = row.Scopes
	}
	items[0].ExpiresAt = row.ExpiresAt
	response.OK(c, gin.H{"items": items})
}

func (h *Handler) CalendarConnect(c *gin.Context) {
	url, err := h.calendar.AuthURL(auth.GetUserID(c).String())
	if err != nil {
		response.ServiceUnavailable(c, err.Error())
		return
	}
	response.OK(c, gin.H{"auth_url": url})
}

func (h *Handler) CalendarCallback(c *gin.Context) {
	code := strings.TrimSpace(c.Query("code"))
	state := strings.TrimSpace(c.Query("state"))
	if code == "" {
		response.BadRequest(c, "missing code")
		return
	}
	userID, err := uuid.Parse(state)
	if err != nil {
		response.BadRequest(c, "invalid state")
		return
	}
	if err := h.calendar.Exchange(c.Request.Context(), userID, code); err != nil {
		response.InternalError(c, err.Error())
		return
	}
	c.Redirect(http.StatusFound, "/settings?calendar=connected")
}

func (h *Handler) CalendarDisconnect(c *gin.Context) {
	if err := h.calendar.Disconnect(auth.GetUserID(c)); err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.NoContent(c)
}

func (h *Handler) CalendarSync(c *gin.Context) {
	userID := auth.GetUserID(c)
	if !h.calendar.Connected(c.Request.Context(), userID) {
		response.BadRequest(c, "google calendar not connected")
		return
	}
	response.OK(c, gin.H{"message": "calendar sync enabled; study reminders will sync automatically"})
}
