package auth

import (
	"errors"
	"log"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/internal/workseed"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type Service struct {
	db        *gorm.DB
	jwtSecret []byte
	jwtIssuer string
	jwtExpiry time.Duration
	fashAuth  FashAuthSettings
}

type FashAuthSettings struct {
	Enabled   bool
	JWTSecret string
	JWTIssuer string
}

func NewService(db *gorm.DB, jwtSecret, jwtIssuer string, jwtExpiry time.Duration, fash FashAuthSettings) *Service {
	return &Service{
		db:        db,
		jwtSecret: []byte(jwtSecret),
		jwtIssuer: jwtIssuer,
		jwtExpiry: jwtExpiry,
		fashAuth:  fash,
	}
}

func (s *Service) UsesFashAuth() bool {
	return s.fashAuth.Enabled
}

type Claims struct {
	UserID uuid.UUID `json:"user_id"`
	jwt.RegisteredClaims
}

func (s *Service) EnsureDefaultUser(email, password, name string) error {
	var count int64
	if err := s.db.Model(&models.User{}).Count(&count).Error; err != nil {
		return err
	}
	if count > 0 {
		return nil
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	return s.db.Create(&models.User{
		Email:        email,
		PasswordHash: string(hash),
		Name:         name,
	}).Error
}

func (s *Service) Login(email, password string) (string, *models.User, error) {
	var user models.User
	if err := s.db.Where("email = ?", email).First(&user).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("[auth] login user not found email=%s", email)
			return "", nil, errors.New("invalid credentials")
		}
		log.Printf("[auth] login db error email=%s: %v", email, err)
		return "", nil, err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		log.Printf("[auth] login password mismatch email=%s", email)
		return "", nil, errors.New("invalid credentials")
	}

	token, err := s.generateToken(user.ID)
	if err != nil {
		log.Printf("[auth] login token error email=%s user_id=%s: %v", email, user.ID, err)
		return "", nil, err
	}

	return token, &user, nil
}

func (s *Service) EnsureUserFromFash(id uuid.UUID, email string) error {
	var user models.User
	err := s.db.First(&user, "id = ?", id).Error
	if err == nil {
		updates := map[string]any{}
		if email != "" && user.Email != email {
			updates["email"] = email
		}
		if len(updates) == 0 {
			return nil
		}
		return s.db.Model(&user).Updates(updates).Error
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	name := "User"
	if email != "" {
		parts := strings.Split(email, "@")
		if parts[0] != "" {
			name = parts[0]
		}
	}

	return s.db.Create(&models.User{
		ID:           id,
		Email:        email,
		PasswordHash: "!",
		Name:         name,
	}).Error
}

func (s *Service) SyncCareerForUser(userID uuid.UUID, email string) {
	if err := workseed.SyncForUser(s.db, userID, email); err != nil {
		log.Printf("[auth] workseed sync email=%s user_id=%s: %v", email, userID, err)
	}
}

func (s *Service) ParseFashToken(tokenStr string) (uuid.UUID, string, error) {
	return parseFashToken(tokenStr, s.fashAuth.JWTSecret, s.fashAuth.JWTIssuer)
}

func (s *Service) GetUser(id uuid.UUID) (*models.User, error) {
	var user models.User
	if err := s.db.First(&user, "id = ?", id).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (s *Service) UpdateProfile(id uuid.UUID, name, email string) (*models.User, error) {
	var user models.User
	if err := s.db.First(&user, "id = ?", id).Error; err != nil {
		return nil, err
	}
	user.Name = name
	if email != "" {
		user.Email = email
	}
	if err := s.db.Save(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (s *Service) ChangePassword(id uuid.UUID, current, newPass string) error {
	var user models.User
	if err := s.db.First(&user, "id = ?", id).Error; err != nil {
		return err
	}
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(current)); err != nil {
		return errors.New("current password is incorrect")
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(newPass), bcrypt.DefaultCost)
	if err != nil {
		return err
	}
	user.PasswordHash = string(hash)
	return s.db.Save(&user).Error
}

func (s *Service) generateToken(userID uuid.UUID) (string, error) {
	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(s.jwtExpiry)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    s.jwtIssuer,
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

func (s *Service) ParseToken(tokenStr string) (uuid.UUID, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(t *jwt.Token) (any, error) {
		return s.jwtSecret, nil
	})
	if err != nil {
		return uuid.Nil, err
	}
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return uuid.Nil, errors.New("invalid token")
	}
	return claims.UserID, nil
}
