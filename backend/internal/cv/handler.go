package cv

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
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
	r.GET("/layouts", h.ListLayouts)
	r.GET("/templates", h.ListTemplates)
	r.POST("/templates/sync-system", h.SyncSystemTemplates)
	r.POST("/templates", h.CreateTemplate)
	r.GET("/templates/:id", h.GetTemplate)
	r.PUT("/templates/:id", h.SaveTemplate)
	r.DELETE("/templates/:id", h.DeleteTemplate)
	r.POST("/templates/:id/validate", h.ValidateTemplate)
	r.POST("/templates/:id/blocks/:blockId/refine", h.RefineTemplateBlock)
	r.POST("/templates/:id/blocks/from-entity", h.AddBlockFromEntity)
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
	templateID := c.Query("template_id")
	if templateID != "" {
		id, err := uuid.Parse(templateID)
		if err != nil {
			response.BadRequest(c, "invalid template_id")
			return
		}
		data, filename, err := h.service.ExportPDFTemplate(auth.GetUserID(c), id)
		if err != nil {
			response.InternalError(c, err.Error())
			return
		}
		c.Header("Content-Type", "application/pdf")
		c.Header("Content-Disposition", `attachment; filename="`+filename+`"`)
		c.Data(http.StatusOK, "application/pdf", data)
		return
	}
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

func (h *Handler) ListLayouts(c *gin.Context) {
	response.OK(c, gin.H{"layouts": ListLayouts()})
}

func (h *Handler) ListTemplates(c *gin.Context) {
	list, err := h.service.ListTemplates(auth.GetUserID(c))
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"templates": list})
}

func (h *Handler) SyncSystemTemplates(c *gin.Context) {
	userID := auth.GetUserID(c)
	if err := h.service.ForceSyncSystemCVSetup(userID); err != nil {
		response.InternalError(c, err.Error())
		return
	}
	list, err := h.service.ListTemplates(userID)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"templates": list})
}

func (h *Handler) CreateTemplate(c *gin.Context) {
	var req CreateTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	tpl, err := h.service.CreateTemplate(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, tpl)
}

func (h *Handler) GetTemplate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	tpl, err := h.service.GetTemplate(auth.GetUserID(c), id)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, tpl)
}

func (h *Handler) SaveTemplate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	var req SaveTemplateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	tpl, err := h.service.SaveTemplate(auth.GetUserID(c), id, req.Template, req.Force)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.OK(c, tpl)
}

func (h *Handler) DeleteTemplate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	if err := h.service.DeleteTemplate(auth.GetUserID(c), id); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.OK(c, gin.H{"deleted": true})
}

func (h *Handler) ValidateTemplate(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	var req SaveTemplateRequest
	_ = c.ShouldBindJSON(&req)
	var override *CVTemplate
	if req.Template.ID != "" {
		override = &req.Template
	}
	result, err := h.service.ValidateTemplate(auth.GetUserID(c), id, override)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, result)
}

func (h *Handler) RefineTemplateBlock(c *gin.Context) {
	var req RefineBlockRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	out, err := h.service.RefineBlock(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, out)
}

func (h *Handler) AddBlockFromEntity(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	var req AddBlockFromEntityRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	tpl, err := h.service.AddBlockFromEntity(auth.GetUserID(c), id, req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, tpl)
}
