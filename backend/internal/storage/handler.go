package storage

import (
	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/entity"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/pkg/response"
	"gorm.io/gorm"
)

type Handler struct {
	service       *Service
	entityService *entity.Service
}

func NewHandler(service *Service, entityService *entity.Service) *Handler {
	return &Handler{service: service, entityService: entityService}
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	r.POST("/upload", h.Upload)
	r.GET("/:id/url", h.GetURL)
}

func (h *Handler) Upload(c *gin.Context) {
	userID := auth.GetUserID(c)
	fileHeader, err := c.FormFile("file")
	if err != nil {
		response.BadRequest(c, "file required")
		return
	}

	var entityID *uuid.UUID
	if eid := c.PostForm("entity_id"); eid != "" {
		id, err := uuid.Parse(eid)
		if err != nil {
			response.BadRequest(c, "invalid entity_id")
			return
		}
		entityID = &id
	}

	result, err := h.service.Upload(userID, entityID, fileHeader)
	if err == ErrStorageNotConfigured {
		response.BadRequest(c, "file storage not configured (SeaweedFS S3 required)")
		return
	}
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}

	// Create inbox file entity if no entity linked
	if entityID == nil {
		ent, err := h.entityService.Create(userID, entity.CreateInput{
			Type:    models.TypeInboxFile,
			Title:   fileHeader.Filename,
			Content: result.URL,
			Source:  "upload",
			Metadata: map[string]any{
				"file_id":     result.File.ID.String(),
				"storage_key": result.File.StorageKey,
				"mime_type":   result.File.MimeType,
				"size":        result.File.Size,
			},
		})
		if err == nil {
			result.File.EntityID = &ent.ID
		}
	}

	response.Created(c, result)
}

func (h *Handler) GetURL(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		response.BadRequest(c, "invalid id")
		return
	}
	f, err := h.service.Get(auth.GetUserID(c), id)
	if err == gorm.ErrRecordNotFound {
		response.NotFound(c, "file not found")
		return
	}
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	url, err := h.service.PresignedURL(auth.GetUserID(c), f.StorageKey)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"url": url})
}
