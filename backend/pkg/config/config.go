package config

import (
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	AppEnv           string
	AppName          string
	AppHost          string
	AppPort          string
	AppPublicURL     string
	LogLevel         string
	DatabaseURL      string
	JWTSecret        string
	JWTIssuer        string
	JWTExpiry        time.Duration
	OpenAIBaseURL    string
	OpenAIAPIKey     string
	OpenAIModel      string
	Storage          StorageConfig
	TrustedProxies   []string
	CORSOrigins      []string
	EmbeddingDim     int
	DefaultUserEmail string
	DefaultUserPass  string
}

func Load() *Config {
	embeddingDim, _ := strconv.Atoi(getEnv("EMBEDDING_DIM", "1536"))
	appName := getEnv("APP_NAME", "personal-os-api")

	return &Config{
		AppEnv:           getEnv("APP_ENV", "development"),
		AppName:          appName,
		AppHost:          getEnv("APP_HOST", "0.0.0.0"),
		AppPort:          getEnv("APP_PORT", "8080"),
		AppPublicURL:     getEnv("APP_PUBLIC_URL", ""),
		LogLevel:         getEnv("LOG_LEVEL", "info"),
		DatabaseURL:      loadDatabaseURL(),
		JWTSecret:        loadJWTSecret(),
		JWTIssuer:        firstNonEmpty(os.Getenv("JWT_ISSUER"), appName),
		JWTExpiry:        time.Duration(parseJWTExpiryHours()) * time.Hour,
		OpenAIBaseURL:    getEnv("OPENAI_BASE_URL", "https://api.openai.com/v1"),
		OpenAIAPIKey:     getEnv("OPENAI_API_KEY", ""),
		OpenAIModel:      getEnv("OPENAI_MODEL", "gpt-4o-mini"),
		Storage:          LoadStorageConfig(),
		TrustedProxies:   loadTrustedProxies(),
		CORSOrigins:      loadCORSOrigins(),
		EmbeddingDim:     embeddingDim,
		DefaultUserEmail: getEnv("DEFAULT_USER_EMAIL", "admin@personal-os.local"),
		DefaultUserPass:  getEnv("DEFAULT_USER_PASSWORD", "changeme123"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func splitCSV(s string) []string {
	s = strings.Trim(s, "\"'")
	parts := strings.Split(s, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}
