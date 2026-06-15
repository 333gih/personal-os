package relation

import (
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
	r.POST("", h.Create)
	r.DELETE("/:id", h.Delete)
}

func (h *Handler) List(c *gin.Context) {
	var entityID *uuid.UUID
	if idStr := c.Query("entity_id"); idStr != "" {
		id, err := uuid.Parse(idStr)
		if err != nil {
			response.BadRequest(c, "invalid entity_id")
			return
		}
		entityID = &id
	}
	rels, err := h.service.List(auth.GetUserID(c), entityID)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"items": rels})
}

func (h *Handler) Create(c *gin.Context) {
	var input CreateInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	rel, err := h.service.Create(auth.GetUserID(c), input)
	if err == gorm.ErrRecordNotFound {
		response.NotFound(c, "one or both entities not found")
		return
	}
	if err == gorm.ErrInvalidData {
		response.BadRequest(c, "source and target must differ")
		return
	}
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.Created(c, rel)
}

func (h *Handler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	if err := h.service.Delete(auth.GetUserID(c), id); err == gorm.ErrRecordNotFound {
		response.NotFound(c, "relationship not found")
		return
	} else if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.NoContent(c)
}
