package config

import (
	"os"
	"strconv"
	"strings"
)

// StorageConfig mirrors fash core-service S3/SeaweedFS settings.
type StorageConfig struct {
	Provider      string
	Endpoint      string
	AccessKey     string
	SecretKey     string
	Bucket        string
	UseSSL        bool
	PublicBaseURL string
	Region        string
}

func (c StorageConfig) IsRemote() bool {
	switch c.Provider {
	case "s3", "minio", "seaweedfs":
		return c.Endpoint != "" && c.AccessKey != "" && c.SecretKey != "" && c.Bucket != ""
	default:
		return false
	}
}

func LoadStorageConfig() StorageConfig {
	cfg := StorageConfig{
		Provider:      strings.TrimSpace(os.Getenv("STORAGE_PROVIDER")),
		Endpoint:      strings.TrimSpace(os.Getenv("S3_ENDPOINT")),
		AccessKey:     strings.TrimSpace(os.Getenv("S3_ACCESS_KEY")),
		SecretKey:     strings.TrimSpace(os.Getenv("S3_SECRET_KEY")),
		Bucket:        strings.TrimSpace(os.Getenv("S3_BUCKET")),
		PublicBaseURL: strings.TrimSpace(os.Getenv("S3_PUBLIC_BASE_URL")),
		Region:        strings.TrimSpace(os.Getenv("S3_REGION")),
	}
	if cfg.Region == "" {
		cfg.Region = "us-east-1"
	}
	cfg.UseSSL, _ = strconv.ParseBool(os.Getenv("S3_USE_SSL"))

	// Legacy MINIO_* fallback for migration
	if cfg.Endpoint == "" {
		cfg.Endpoint = strings.TrimSpace(os.Getenv("MINIO_ENDPOINT"))
	}
	if cfg.AccessKey == "" {
		cfg.AccessKey = strings.TrimSpace(os.Getenv("MINIO_ACCESS_KEY"))
	}
	if cfg.SecretKey == "" {
		cfg.SecretKey = strings.TrimSpace(os.Getenv("MINIO_SECRET_KEY"))
	}
	if cfg.Bucket == "" {
		cfg.Bucket = strings.TrimSpace(os.Getenv("MINIO_BUCKET"))
	}
	if cfg.Provider == "" && cfg.Endpoint != "" {
		cfg.Provider = "seaweedfs"
	}
	return cfg
}
