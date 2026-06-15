package entity

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/pkg/response"
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
	r.GET("/:id", h.Get)
	r.GET("/:id/detail", h.GetDetail)
	r.PUT("/:id", h.Update)
	r.DELETE("/:id", h.Delete)
}

func (h *Handler) List(c *gin.Context) {
	userID := auth.GetUserID(c)
	filter := ListFilter{
		Domain: c.Query("domain"),
		Type:   c.Query("type"),
		Tag:    c.Query("tag"),
		Status: c.DefaultQuery("status", "active"),
	}
	if v := c.Query("limit"); v != "" {
		if n, err := parseInt(v); err == nil {
			filter.Limit = n
		}
	}
	if v := c.Query("offset"); v != "" {
		if n, err := parseInt(v); err == nil {
			filter.Offset = n
		}
	}

	entities, total, err := h.service.List(userID, filter)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"items": entities, "total": total})
}

func (h *Handler) Create(c *gin.Context) {
	var input CreateInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	entity, err := h.service.Create(auth.GetUserID(c), input)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.Created(c, entity)
}

func (h *Handler) Get(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	entity, err := h.service.Get(auth.GetUserID(c), id)
	if IsNotFound(err) {
		response.NotFound(c, "entity not found")
		return
	}
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, entity)
}

func (h *Handler) GetDetail(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	includeInsights := c.Query("insights") == "true"
	detail, err := h.service.GetDetail(auth.GetUserID(c), id, includeInsights)
	if IsNotFound(err) {
		response.NotFound(c, "entity not found")
		return
	}
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, detail)
}

func (h *Handler) Update(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	var input UpdateInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	entity, err := h.service.Update(auth.GetUserID(c), id, input)
	if IsNotFound(err) {
		response.NotFound(c, "entity not found")
		return
	}
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, entity)
}

func (h *Handler) Delete(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	if err := h.service.Delete(auth.GetUserID(c), id); IsNotFound(err) {
		response.NotFound(c, "entity not found")
		return
	} else if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.NoContent(c)
}

func parseInt(s string) (int, error) {
	var n int
	for _, c := range s {
		if c < '0' || c > '9' {
			return 0, gin.Error{}
		}
		n = n*10 + int(c-'0')
	}
	return n, nil
}
