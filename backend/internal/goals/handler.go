package goals

import (
	"strings"

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
	r.GET("/summary", h.Summary)
	r.POST("/reflect", h.Reflect)
}

func (h *Handler) Summary(c *gin.Context) {
	result, err := h.service.Summary(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, result)
}

func (h *Handler) Reflect(c *gin.Context) {
	var req ReflectInput
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	result, err := h.service.Reflect(auth.GetUserID(c), req)
	if err != nil {
		if strings.Contains(err.Error(), "AI not configured") {
			response.ServiceUnavailable(c, err.Error())
			return
		}
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, result)
}
