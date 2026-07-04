package modules

import (
	"errors"
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
	r.GET("", h.List)
	r.PUT("", h.Update)
}

func (h *Handler) List(c *gin.Context) {
	result, err := h.service.List(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, result)
}

func (h *Handler) Update(c *gin.Context) {
	var req UpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	result, err := h.service.Update(auth.GetUserID(c), req)
	if err != nil {
		switch {
		case errors.Is(err, ErrUnknownModule):
			response.BadRequest(c, err.Error())
		case errors.Is(err, ErrModuleRequired), errors.Is(err, ErrMinDomains), errors.Is(err, ErrMaxDomains):
			response.BadRequest(c, err.Error())
		case strings.Contains(err.Error(), ErrDependencyDisabled.Error()):
			response.BadRequest(c, err.Error())
		default:
			response.InternalError(c, err.Error())
		}
		return
	}
	response.OK(c, result)
}
