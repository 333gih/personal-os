package storage

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"path/filepath"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/personal-os/backend/internal/models"
	"github.com/personal-os/backend/pkg/config"
	"gorm.io/gorm"
)

var ErrStorageNotConfigured = fmt.Errorf("object storage not configured")

type Service struct {
	db  *gorm.DB
	s3  *S3Storage
	cfg config.StorageConfig
}

type UploadResult struct {
	File models.File `json:"file"`
	URL  string      `json:"url"`
}

func NewService(db *gorm.DB, cfg config.StorageConfig) (*Service, error) {
	s3, err := NewS3Storage(cfg)
	if err != nil {
		return nil, err
	}
	if s3 != nil {
		if err := s3.EnsureBucket(context.Background()); err != nil {
			return nil, fmt.Errorf("ensure bucket: %w", err)
		}
	}
	return &Service{db: db, s3: s3, cfg: cfg}, nil
}

func (s *Service) Enabled() bool {
	return s.s3 != nil
}

func (s *Service) Upload(userID uuid.UUID, entityID *uuid.UUID, header *multipart.FileHeader) (*UploadResult, error) {
	if s.s3 == nil {
		return nil, ErrStorageNotConfigured
	}

	file, err := header.Open()
	if err != nil {
		return nil, err
	}
	defer file.Close()

	ext := filepath.Ext(header.Filename)
	// personal-os/ prefix keeps objects separate from fash-uploads bucket if shared
	key := fmt.Sprintf("personal-os/%s/%s%s", userID.String(), uuid.New().String(), ext)

	contentType := header.Header.Get("Content-Type")
	if contentType == "" {
		contentType = "application/octet-stream"
	}

	_, err = s.s3.client.PutObject(context.Background(), s.s3.bucket, key, file, header.Size, minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return nil, err
	}

	record := models.File{
		UserID:     userID,
		EntityID:   entityID,
		Filename:   header.Filename,
		MimeType:   contentType,
		Size:       header.Size,
		StorageKey: key,
	}
	if err := s.db.Create(&record).Error; err != nil {
		return nil, err
	}

	url, err := s.s3.PresignURL(context.Background(), key, 24*time.Hour)
	if err != nil {
		url = s.s3.PublicURL(key)
	}

	return &UploadResult{File: record, URL: url}, nil
}

func (s *Service) Get(userID, id uuid.UUID) (*models.File, error) {
	var f models.File
	err := s.db.Where("id = ? AND user_id = ?", id, userID).First(&f).Error
	return &f, err
}

func (s *Service) PresignedURL(userID uuid.UUID, storageKey string) (string, error) {
	if s.s3 == nil {
		return "", ErrStorageNotConfigured
	}
	if !strings.HasPrefix(storageKey, "personal-os/"+userID.String()+"/") &&
		!strings.HasPrefix(storageKey, userID.String()+"/") {
		return "", fmt.Errorf("access denied")
	}
	return s.s3.PresignURL(context.Background(), storageKey, 24*time.Hour)
}

func (s *Service) Download(userID uuid.UUID, storageKey string) (io.ReadCloser, *models.File, error) {
	if s.s3 == nil {
		return nil, nil, ErrStorageNotConfigured
	}
	var f models.File
	if err := s.db.Where("storage_key = ? AND user_id = ?", storageKey, userID).First(&f).Error; err != nil {
		return nil, nil, err
	}
	obj, err := s.s3.GetObject(context.Background(), storageKey)
	if err != nil {
		return nil, nil, err
	}
	return obj, &f, nil
}
