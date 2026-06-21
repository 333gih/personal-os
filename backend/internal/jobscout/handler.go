package jobscout

import (
	"net/http"
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
	r.GET("/preferences", h.GetPreferences)
	r.PUT("/preferences", h.SavePreferences)
	r.GET("/scan/status", h.ScanStatus)
	r.POST("/scan", h.Scan)
	r.GET("", h.List)
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
	st := h.service.StartScanAsync(auth.GetUserID(c))
	if st.Status == "running" && st.Result == nil {
		c.JSON(http.StatusAccepted, st)
		return
	}
	response.OK(c, st)
}

func (h *Handler) ScanStatus(c *gin.Context) {
	st := h.service.ScanStatus(auth.GetUserID(c))
	response.OK(c, st)
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

func (h *Handler) GetPreferences(c *gin.Context) {
	prefs, err := h.service.GetPreferences(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, prefs)
}

func (h *Handler) SavePreferences(c *gin.Context) {
	var req SearchPreferences
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	prefs, err := h.service.SavePreferences(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, prefs)
}
