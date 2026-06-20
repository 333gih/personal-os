package auth

import (
	"log"

	"github.com/gin-gonic/gin"
	"github.com/personal-os/backend/pkg/response"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

type loginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required"`
}

type profileRequest struct {
	Name  string `json:"name"`
	Email string `json:"email"`
}

type passwordRequest struct {
	CurrentPassword string `json:"current_password" binding:"required"`
	NewPassword     string `json:"new_password" binding:"required,min=8"`
}

func (h *Handler) RegisterRoutes(r *gin.RouterGroup) {
	r.POST("/login", h.Login)
	h.RegisterProfileRoutes(r)
}

func (h *Handler) RegisterProfileRoutes(r *gin.RouterGroup) {
	r.GET("/me", Middleware(h.service), h.Me)
	r.PUT("/profile", Middleware(h.service), h.UpdateProfile)
	r.PUT("/password", Middleware(h.service), h.ChangePassword)
}

func (h *Handler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("[auth] login bind error ip=%s: %v", c.ClientIP(), err)
		response.BadRequest(c, err.Error())
		return
	}

	log.Printf("[auth] login attempt email=%s ip=%s origin=%s", req.Email, c.ClientIP(), c.GetHeader("Origin"))

	token, user, err := h.service.Login(req.Email, req.Password)
	if err != nil {
		log.Printf("[auth] login failed email=%s ip=%s: %v", req.Email, c.ClientIP(), err)
		response.Unauthorized(c, err.Error())
		return
	}

	log.Printf("[auth] login success email=%s user_id=%s ip=%s", user.Email, user.ID, c.ClientIP())
	response.OK(c, gin.H{
		"token": token,
		"user":  user,
	})
}

func (h *Handler) Me(c *gin.Context) {
	userID := GetUserID(c)
	user, err := h.service.GetUser(userID)
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}
	h.service.SyncCareerForUser(userID, user.Email)
	response.OK(c, user)
}

func (h *Handler) UpdateProfile(c *gin.Context) {
	var req profileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	user, err := h.service.UpdateProfile(GetUserID(c), req.Name, req.Email)
	if err != nil {
		response.InternalError(c, err.Error())
		return
	}
	response.OK(c, user)
}

func (h *Handler) ChangePassword(c *gin.Context) {
	var req passwordRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	if err := h.service.ChangePassword(GetUserID(c), req.CurrentPassword, req.NewPassword); err != nil {
		response.BadRequest(c, err.Error())
		return
	}
	response.OK(c, gin.H{"message": "password updated"})
}
