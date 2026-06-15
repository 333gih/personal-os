package search

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
	r.POST("", h.Search)
	r.GET("", h.SearchGET)
}

func (h *Handler) Search(c *gin.Context) {
	var req Request
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	results, err := h.service.Search(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"results": results, "count": len(results)})
}

func (h *Handler) SearchGET(c *gin.Context) {
	req := Request{
		Query:  c.Query("q"),
		Mode:   c.DefaultQuery("mode", "hybrid"),
		Domain: c.Query("domain"),
	}
	if req.Query == "" {
		response.BadRequest(c, "q parameter required")
		return
	}
	results, err := h.service.Search(auth.GetUserID(c), req)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, gin.H{"results": results, "count": len(results)})
}
