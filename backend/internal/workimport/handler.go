package workimport

import (
	"fmt"
	"io"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/pkg/response"
)

const maxDiagramBytes = 12 << 20 // 12 MiB

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	r.POST("/import", h.Import)
}

type jsonImportRequest struct {
	Title    string `json:"title"`
	Company  string `json:"company"`
	Markdown string `json:"markdown"`
}

func (h *Handler) Import(c *gin.Context) {
	input, err := h.parseImport(c)
	if err != nil {
		response.BadRequest(c, err.Error())
		return
	}

	result, err := h.service.Import(auth.GetUserID(c), input)
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

func (h *Handler) parseImport(c *gin.Context) (ImportInput, error) {
	contentType := c.GetHeader("Content-Type")
	if strings.HasPrefix(contentType, "multipart/form-data") {
		return h.parseMultipart(c)
	}

	var req jsonImportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		return ImportInput{}, err
	}
	return ImportInput{
		TitleHint:   strings.TrimSpace(req.Title),
		CompanyHint: strings.TrimSpace(req.Company),
		Markdown:    strings.TrimSpace(req.Markdown),
	}, nil
}

func (h *Handler) parseMultipart(c *gin.Context) (ImportInput, error) {
	input := ImportInput{
		TitleHint:   strings.TrimSpace(c.PostForm("title")),
		CompanyHint: strings.TrimSpace(c.PostForm("company")),
		Markdown:    strings.TrimSpace(c.PostForm("markdown")),
	}
	if input.Markdown == "" {
		input.Markdown = strings.TrimSpace(c.PostForm("notes"))
	}

	file, header, err := c.Request.FormFile("diagram")
	if err != nil {
		return input, nil
	}
	defer file.Close()

	limited := io.LimitReader(file, maxDiagramBytes+1)
	data, err := io.ReadAll(limited)
	if err != nil {
		return ImportInput{}, err
	}
	if len(data) > maxDiagramBytes {
		return ImportInput{}, fmt.Errorf("diagram exceeds %d MB limit", maxDiagramBytes/(1<<20))
	}
	input.ImageData = data
	input.ImageMIME = detectMIME(header.Filename, header.Header.Get("Content-Type"))
	return input, nil
}
