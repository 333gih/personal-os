package studylearning

import (
	"errors"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/internal/notification"
	"github.com/personal-os/backend/pkg/response"
	"gorm.io/gorm"
)

type Handler struct {
	svc    *Service
	notify *notification.Service
}

func NewHandler(svc *Service, notify *notification.Service) *Handler {
	return &Handler{svc: svc, notify: notify}
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	r.GET("/schedule", h.GetSchedule)
	r.PUT("/schedule", h.PutSchedule)
	r.GET("/today", h.Today)
	r.GET("/dsa/today", h.DSAToday)
	r.GET("/notifications/log", h.NotificationLog)
	r.POST("/coach/async", h.CoachAsync)
	r.GET("/jobs/:id", h.GetJob)
	r.GET("/lessons/:id", h.GetLesson)
}

func (h *Handler) GetSchedule(c *gin.Context) {
	out, err := h.svc.GetSchedule(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) PutSchedule(c *gin.Context) {
	var req ScheduleDTO
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	out, err := h.svc.PutSchedule(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) Today(c *gin.Context) {
	out, err := h.svc.Today(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) DSAToday(c *gin.Context) {
	out, err := h.svc.DSADailyFocus(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) NotificationLog(c *gin.Context) {
	limit := 50
	logs, err := h.notify.List(auth.GetUserID(c), limit)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"items": logs})
}

type coachAsyncRequest struct {
	EntityID string `json:"entity_id"`
	Topic    string `json:"topic"`
	Track    string `json:"track"`
	Focus    string `json:"focus"`
}

func (h *Handler) CoachAsync(c *gin.Context) {
	var req coachAsyncRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	out, err := h.svc.EnqueueCoach(auth.GetUserID(c), CoachAsyncInput{
		EntityID: req.EntityID,
		Topic:    req.Topic,
		Track:    req.Track,
		Focus:    req.Focus,
	})
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.Created(c, out)
}

func (h *Handler) GetLesson(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid lesson id")
		return
	}
	out, err := h.svc.GetLesson(auth.GetUserID(c), id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			response.NotFound(c, "lesson not found")
			return
		}
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) GetJob(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid job id")
		return
	}
	out, err := h.svc.GetJob(auth.GetUserID(c), id)
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			response.NotFound(c, "job not found")
			return
		}
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}
