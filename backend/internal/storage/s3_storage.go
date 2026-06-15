package storage

import (
	"context"
	"fmt"
	neturl "net/url"
	"strings"
	"time"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
	"github.com/personal-os/backend/pkg/config"
)

// S3Storage uses SeaweedFS / S3-compatible storage (same pattern as fash core-service).
type S3Storage struct {
	client        *minio.Client
	presignClient *minio.Client
	bucket        string
	baseURL       string
}

func NewS3Storage(cfg config.StorageConfig) (*S3Storage, error) {
	if !cfg.IsRemote() {
		return nil, nil
	}

	client, err := minio.New(cfg.Endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
		Secure: cfg.UseSSL,
		Region: cfg.Region,
	})
	if err != nil {
		return nil, fmt.Errorf("s3 client init: %w", err)
	}

	baseURL := strings.TrimSuffix(cfg.PublicBaseURL, "/")
	if baseURL == "" {
		scheme := "http"
		if cfg.UseSSL {
			scheme = "https"
		}
		baseURL = fmt.Sprintf("%s://%s/%s", scheme, cfg.Endpoint, cfg.Bucket)
	}

	presignClient := client
	if cfg.PublicBaseURL != "" {
		if parsed, err := neturl.Parse(cfg.PublicBaseURL); err == nil && parsed.Host != "" {
			pubSecure := parsed.Scheme == "https"
			if pc, err := minio.New(parsed.Host, &minio.Options{
				Creds:  credentials.NewStaticV4(cfg.AccessKey, cfg.SecretKey, ""),
				Secure: pubSecure,
				Region: cfg.Region,
			}); err == nil {
				presignClient = pc
			}
		}
	}

	return &S3Storage{
		client:        client,
		presignClient: presignClient,
		bucket:        cfg.Bucket,
		baseURL:       baseURL,
	}, nil
}

func (s *S3Storage) EnsureBucket(ctx context.Context) error {
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()

	exists, err := s.client.BucketExists(ctx, s.bucket)
	if err != nil {
		return fmt.Errorf("bucket exists check: %w", err)
	}
	if exists {
		return nil
	}
	return s.client.MakeBucket(ctx, s.bucket, minio.MakeBucketOptions{})
}

func (s *S3Storage) publicObjectURLForKey(key string) string {
	base := strings.TrimSuffix(s.baseURL, "/")
	if s.bucket != "" && !strings.HasSuffix(base, "/"+s.bucket) {
		return base + "/" + s.bucket + "/" + key
	}
	return base + "/" + key
}

func (s *S3Storage) PresignURL(ctx context.Context, key string, ttl time.Duration) (string, error) {
	u, err := s.presignClient.PresignedGetObject(ctx, s.bucket, key, ttl, nil)
	if err != nil {
		return "", err
	}
	return u.String(), nil
}

func (s *S3Storage) GetObject(ctx context.Context, key string) (*minio.Object, error) {
	return s.client.GetObject(ctx, s.bucket, key, minio.GetObjectOptions{})
}

func (s *S3Storage) PublicURL(key string) string {
	return s.publicObjectURLForKey(key)
}
