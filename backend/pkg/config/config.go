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
	OpenAIModel          string
	OpenAIVisionModel    string
	OpenAIEmbeddingModel string
	OpenRouterSiteURL    string
	OpenRouterAppName    string
	Storage          StorageConfig
	TrustedProxies   []string
	CORSOrigins      []string
	EmbeddingDim     int
	DefaultUserEmail string
	DefaultUserPass  string
	FashAuth         FashAuthConfig
	AI               AIConfig
	Notification     NotificationConfig
	GoogleCalendar   GoogleCalendarConfig
}

type GoogleCalendarConfig struct {
	ClientID     string
	ClientSecret string
	RedirectURL  string
}

func Load() *Config {
	embeddingDim, _ := strconv.Atoi(getEnv("EMBEDDING_DIM", "1536"))
	appName := getEnv("APP_NAME", "personal-os-api")
	appPublicURL := getEnv("APP_PUBLIC_URL", "")
	baseURL := getEnv("OPENAI_BASE_URL", "")
	if baseURL == "" {
		baseURL = getEnv("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
	}
	chatModel := getEnv("OPENAI_MODEL", "")
	if chatModel == "" {
		chatModel = getEnv("OPENROUTER_MODEL", "deepseek/deepseek-chat")
	}
	embedModel := getEnv("OPENAI_EMBEDDING_MODEL", "openai/text-embedding-3-small")
	visionModel := getEnv("OPENROUTER_VISION_MODEL", "")
	if visionModel == "" {
		visionModel = getEnv("OPENAI_VISION_MODEL", "google/gemini-2.0-flash-001")
	}

	return &Config{
		AppEnv:               getEnv("APP_ENV", "development"),
		AppName:              appName,
		AppHost:              getEnv("APP_HOST", "0.0.0.0"),
		AppPort:              getEnv("APP_PORT", "8080"),
		AppPublicURL:         appPublicURL,
		LogLevel:             getEnv("LOG_LEVEL", "info"),
		DatabaseURL:          loadDatabaseURL(),
		JWTSecret:            loadJWTSecret(),
		JWTIssuer:            firstNonEmpty(os.Getenv("JWT_ISSUER"), appName),
		JWTExpiry:            time.Duration(parseJWTExpiryHours()) * time.Hour,
		OpenAIBaseURL:        strings.TrimSuffix(baseURL, "/"),
		OpenAIAPIKey:         resolveLLMAPIKey(),
		OpenAIModel:          chatModel,
		OpenAIVisionModel:    visionModel,
		OpenAIEmbeddingModel: embedModel,
		OpenRouterSiteURL:    firstNonEmpty(getEnv("OPENROUTER_SITE_URL", ""), appPublicURL, "https://personal-os.fashandcurious.com"),
		OpenRouterAppName:    firstNonEmpty(getEnv("OPENROUTER_APP_NAME", ""), "Personal OS"),
		Storage:              LoadStorageConfig(),
		TrustedProxies:       loadTrustedProxies(),
		CORSOrigins:          loadCORSOrigins(),
		EmbeddingDim:         embeddingDim,
		DefaultUserEmail:     getEnv("DEFAULT_USER_EMAIL", "admin@personal-os.local"),
		DefaultUserPass:      getEnv("DEFAULT_USER_PASSWORD", "changeme123"),
		FashAuth:             loadFashAuthConfig(),
		AI:                   loadAIConfig(),
		Notification:         loadNotificationConfig(),
		GoogleCalendar:         loadGoogleCalendarConfig(appPublicURL),
	}
}

func loadGoogleCalendarConfig(appPublicURL string) GoogleCalendarConfig {
	redirect := getEnv("GOOGLE_CALENDAR_REDIRECT_URL", "")
	if redirect == "" && appPublicURL != "" {
		redirect = strings.TrimSuffix(appPublicURL, "/") + "/api/v1/integrations/calendar/callback"
	}
	return GoogleCalendarConfig{
		ClientID:     getEnv("GOOGLE_CALENDAR_CLIENT_ID", ""),
		ClientSecret: getEnv("GOOGLE_CALENDAR_CLIENT_SECRET", ""),
		RedirectURL:  redirect,
	}
}

func resolveLLMAPIKey() string {
	for _, key := range []string{"OPENROUTER_API_KEY", "OPENAI_API_KEY"} {
		if v := strings.TrimSpace(os.Getenv(key)); v != "" {
			return v
		}
	}
	return ""
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
