package startupimport

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
	r.POST("/add", h.Add)
}

type addRequest struct {
	Kind      string `json:"kind"`
	RawText   string `json:"raw_text"`
	TitleHint string `json:"title_hint"`
}

func (h *Handler) Add(c *gin.Context) {
	var req addRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	result, err := h.service.Add(auth.GetUserID(c), AddInput{
		Kind: req.Kind, RawText: req.RawText, TitleHint: req.TitleHint,
	})
	if err != nil {
		if strings.Contains(err.Error(), "AI not configured") {
			response.ServiceUnavailable(c, err.Error())
			return
		}
		response.InternalError(c, err.Error())
		return
	}
	response.Created(c, result)
}
