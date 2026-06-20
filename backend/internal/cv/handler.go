package cv

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/internal/storage"
	"github.com/personal-os/backend/pkg/response"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	r.GET("", h.Get)
	r.PUT("", h.Save)
	r.POST("/refine", h.Refine)
	r.POST("/suggest-skills", h.SuggestSkills)
	r.POST("/skills/add", h.AddSkill)
	r.GET("/export/html", h.ExportHTML)
	r.GET("/export/pdf", h.ExportPDF)
	r.POST("/share", h.Share)
}

func (h *Handler) Get(c *gin.Context) {
	cv, err := h.service.Get(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, cv)
}

func (h *Handler) Save(c *gin.Context) {
	var req SaveRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	cv, err := h.service.Save(auth.GetUserID(c), req.Document)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, cv)
}

func (h *Handler) Refine(c *gin.Context) {
	var req RefineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	out, err := h.service.Refine(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) SuggestSkills(c *gin.Context) {
	out, err := h.service.SuggestSkills(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) AddSkill(c *gin.Context) {
	var req AddSkillRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	out, err := h.service.AddSkill(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) ExportHTML(c *gin.Context) {
	html, err := h.service.ExportHTML(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	c.Header("Content-Type", "text/html; charset=utf-8")
	c.String(http.StatusOK, html)
}

func (h *Handler) ExportPDF(c *gin.Context) {
	data, filename, err := h.service.ExportPDF(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	c.Header("Content-Type", "application/pdf")
	c.Header("Content-Disposition", `attachment; filename="`+filename+`"`)
	c.Data(http.StatusOK, "application/pdf", data)
}

func (h *Handler) Share(c *gin.Context) {
	out, err := h.service.SharePDF(auth.GetUserID(c))
	if err == storage.ErrStorageNotConfigured {
		response.BadRequest(c, "file storage not configured — set SeaweedFS S3 env on API")
		return
	}
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}
