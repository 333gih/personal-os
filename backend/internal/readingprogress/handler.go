package readingprogress

import (
	"github.com/gin-gonic/gin"
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
	r.POST("", h.Save)
	r.GET("/current", h.Current)
}

func (h *Handler) Save(c *gin.Context) {
	var input SaveInput
	if err := c.ShouldBindJSON(&input); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	item, err := h.service.Save(auth.GetUserID(c), input)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, item)
}

func (h *Handler) Current(c *gin.Context) {
	items, err := h.service.ListCurrent(auth.GetUserID(c), 50)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"items": items})
}
