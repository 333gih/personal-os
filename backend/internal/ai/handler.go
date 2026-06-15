package ai

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
	r.POST("/analyze", h.Analyze)
}

func (h *Handler) Analyze(c *gin.Context) {
	var req AnalyzeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	result, err := h.service.AnalyzeRequest(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, result)
}
