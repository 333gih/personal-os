package reminder

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/pkg/response"
	"gorm.io/gorm"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	r.GET("", h.List)
	r.GET("/upcoming", h.Upcoming)
	r.POST("", h.Create)
	r.POST("/:id/complete", h.Complete)
	r.DELETE("/:id", h.Delete)
}

func (h *Handler) List(c *gin.Context) {
	reminders, err := h.service.List(auth.GetUserID(c), c.Query("status"))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"items": reminders})
}

func (h *Handler) Upcoming(c *gin.Context) {
	days, _ := strconv.Atoi(c.DefaultQuery("days", "7"))
	reminders, err := h.service.Upcoming(auth.GetUserID(c), days)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"items": reminders})
}

func (h *Handler) Create(c *gin.Context) {
	var input CreateInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	reminder, err := h.service.Create(auth.GetUserID(c), input)
	if err == gorm.ErrRecordNotFound {
		response.NotFound(c, "entity not found")
		return
	}
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.Created(c, reminder)
}

func (h *Handler) Complete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	if err := h.service.Complete(auth.GetUserID(c), id); err == gorm.ErrRecordNotFound {
		response.NotFound(c, "reminder not found")
		return
	} else if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"message": "completed"})
}

func (h *Handler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	if err := h.service.Delete(auth.GetUserID(c), id); err == gorm.ErrRecordNotFound {
		response.NotFound(c, "reminder not found")
		return
	} else if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.NoContent(c)
}
