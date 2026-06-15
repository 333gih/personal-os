package dashboard

import (
	"github.com/gin-gonic/gin"
	"github.com/personal-os/backend/internal/entity"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/reminder"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/pkg/response"
)

type Handler struct {
	entityService   *entity.Service
	reminderService *reminder.Service
}

func NewHandler(entityService *entity.Service, reminderService *reminder.Service) *Handler {
	return &Handler{entityService: entityService, reminderService: reminderService}
}

type DashboardResponse struct {
	DomainCounts map[string]int64      `json:"domain_counts"`
	Recent       []models.Entity       `json:"recent"`
	Upcoming     []models.Reminder     `json:"upcoming_reminders"`
	InboxCount   int64                 `json:"inbox_count"`
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	r.GET("", h.Get)
}

func (h *Handler) Get(c *gin.Context) {
	userID := auth.GetUserID(c)

	counts, err := h.entityService.CountByDomain(userID)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	recent, err := h.entityService.Recent(userID, 10)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	upcoming, err := h.reminderService.Upcoming(userID, 7)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	inboxCount := counts[models.DomainInbox]

	response.OK(c, DashboardResponse{
		DomainCounts: counts,
		Recent:       recent,
		Upcoming:     upcoming,
		InboxCount:   inboxCount,
	})
}
