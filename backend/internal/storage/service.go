package storage

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"log"
	"mime/multipart"
	"os"
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
	s3, activeCfg, err := connectStorage(cfg)
	if err != nil {
		log.Printf("storage: %v", err)
	}
	return &Service{db: db, s3: s3, cfg: activeCfg}, nil
}

func connectStorage(cfg config.StorageConfig) (*S3Storage, config.StorageConfig, error) {
	if !cfg.IsRemote() {
		return nil, cfg, nil
	}
	for _, bucket := range bucketCandidates(cfg.Bucket) {
		try := cfg
		try.Bucket = bucket
		s3, err := NewS3Storage(try)
		if err != nil {
			continue
		}
		if err := s3.EnsureBucket(context.Background()); err != nil {
			log.Printf("storage: bucket %q unavailable: %v", bucket, err)
			continue
		}
		log.Printf("storage: SeaweedFS ready bucket=%q endpoint=%s", bucket, cfg.Endpoint)
		return s3, try, nil
	}
	return nil, cfg, fmt.Errorf("no reachable S3 bucket (tried %v) — use S3_BUCKET=fash-uploads on fash VPS", bucketCandidates(cfg.Bucket))
}

func bucketCandidates(primary string) []string {
	seen := map[string]bool{}
	add := func(b string) {
		b = strings.TrimSpace(b)
		if b == "" || seen[b] {
			return
		}
		seen[b] = true
	}
	add(primary)
	add(os.Getenv("S3_FALLBACK_BUCKET"))
	add("fash-uploads")
	add("personal-os")
	out := make([]string, 0, len(seen))
	for b := range seen {
		out = append(out, b)
	}
	return out
}

func (s *Service) Enabled() bool {
	return s.s3 != nil
}

type Status struct {
	Enabled  bool   `json:"enabled"`
	Bucket   string `json:"bucket,omitempty"`
	Endpoint string `json:"endpoint,omitempty"`
}

func (s *Service) StorageStatus() Status {
	if s.s3 == nil {
		return Status{Enabled: false, Bucket: s.cfg.Bucket, Endpoint: s.cfg.Endpoint}
	}
	return Status{Enabled: true, Bucket: s.s3.bucket, Endpoint: s.cfg.Endpoint}
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
	key := s.s3.ObjectKey(userID, uuid.New().String()+ext)

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
	if !strings.HasPrefix(storageKey, userID.String()+"/") &&
		!strings.HasPrefix(storageKey, "personal-os/"+userID.String()+"/") {
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

// UploadBytes stores raw bytes (e.g. generated CV PDF) under personal-os/{userId}/{relativeKey}.
func (s *Service) UploadBytes(userID uuid.UUID, relativeKey, contentType string, data []byte) (string, error) {
	if s.s3 == nil {
		return "", ErrStorageNotConfigured
	}
	if !strings.HasPrefix(relativeKey, "cv/") && !strings.HasPrefix(relativeKey, "work/") {
		return "", fmt.Errorf("invalid upload path")
	}
	key := s.s3.ObjectKey(userID, relativeKey)
	reader := bytes.NewReader(data)
	_, err := s.s3.client.PutObject(context.Background(), s.s3.bucket, key, reader, int64(len(data)), minio.PutObjectOptions{
		ContentType: contentType,
	})
	if err != nil {
		return "", err
	}
	record := models.File{
		UserID:     userID,
		Filename:   filepath.Base(relativeKey),
		MimeType:   contentType,
		Size:       int64(len(data)),
		StorageKey: key,
	}
	if err := s.db.Create(&record).Error; err != nil {
		return "", err
	}
	url, err := s.s3.PresignURL(context.Background(), key, 24*time.Hour)
	if err != nil {
		url = s.s3.PublicURL(key)
	}
	return url, nil
}
