package learningimport

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
	r.POST("/coach", h.Coach)
}

type addRequest struct {
	Kind      string `json:"kind"`
	RawText   string `json:"raw_text"`
	TitleHint string `json:"title_hint"`
	Track     string `json:"track"`
}

func (h *Handler) Add(c *gin.Context) {
	var req addRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	result, err := h.service.Add(auth.GetUserID(c), AddInput{
		Kind: req.Kind, RawText: req.RawText, TitleHint: req.TitleHint, Track: req.Track,
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

type coachRequest struct {
	EntityID string `json:"entity_id"`
	Topic    string `json:"topic"`
	Track    string `json:"track"`
	Focus    string `json:"focus"`
}

func (h *Handler) Coach(c *gin.Context) {
	var req coachRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	result, err := h.service.Coach(auth.GetUserID(c), CoachInput{
		EntityID: req.EntityID,
		Topic:    req.Topic,
		Track:    req.Track,
		Focus:    req.Focus,
	})
	if err != nil {
		if strings.Contains(err.Error(), "AI not configured") {
			response.ServiceUnavailable(c, err.Error())
			return
		}
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, result)
}
