package jobscout

import (
	"strconv"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/internal/models"
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
	r.POST("/scan", h.Scan)
	r.PATCH("/:id/status", h.UpdateStatus)
}

func (h *Handler) List(c *gin.Context) {
	status := c.DefaultQuery("status", models.JobStatusOpen)
	opts := ListOptions{
		Status: status,
		Limit:  50,
	}
	if status == models.JobStatusOpen {
		opts.MinScore = MinMatchScore
	}
	if v := c.Query("min_score"); v != "" {
		if f, err := strconv.ParseFloat(v, 32); err == nil {
			opts.MinScore = float32(f)
		}
	}

	jobs, err := h.service.List(auth.GetUserID(c), opts)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"jobs": jobs, "min_score": opts.MinScore})
}

func (h *Handler) Scan(c *gin.Context) {
	out, err := h.service.Scan(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) UpdateStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid job id")
		return
	}
	var req UpdateStatusRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	if err := h.service.UpdateStatus(auth.GetUserID(c), id, req.Status); err != nil {
		response.NotFound(c, "job not found")
		return
	}
	response.OK(c, gin.H{"status": req.Status})
}
