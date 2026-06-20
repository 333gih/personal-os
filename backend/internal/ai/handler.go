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
	r.GET("/status", h.Status)
	r.POST("/analyze", h.Analyze)
}

func (h *Handler) Status(c *gin.Context) {
	response.OK(c, h.service.Status())
}

func (h *Handler) Analyze(c *gin.Context) {
	if !h.service.Configured() {
		response.ServiceUnavailable(c, "AI is not configured on this server")
		return
	}
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
