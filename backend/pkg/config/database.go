package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

func loadDatabaseURL() string {
	if v := strings.TrimSpace(os.Getenv("DATABASE_URL")); v != "" {
		return v
	}

	host := firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_HOST"),
		os.Getenv("POSTGRES_HOST"),
		"localhost",
	)
	port := firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_PORT"),
		os.Getenv("POSTGRES_PORT"),
		"5432",
	)
	name := firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_NAME"),
		os.Getenv("POSTGRES_DB"),
		"personalos",
	)
	user := firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_USER"),
		os.Getenv("POSTGRES_USER"),
		"personalos",
	)
	pass := firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_PASSWORD"),
		os.Getenv("POSTGRES_PASSWORD"),
		"personalos",
	)
	sslMode := firstNonEmpty(os.Getenv("POSTGRES_SSL_MODE"), "disable")

	return fmt.Sprintf(
		"postgres://%s:%s@%s:%s/%s?sslmode=%s",
		user, pass, host, port, name, sslMode,
	)
}

func loadJWTSecret() string {
	return firstNonEmpty(
		os.Getenv("JWT_SECRET"),
		os.Getenv("ACCESS_TOKEN_SECRET"),
		"change-me-in-production",
	)
}

func loadCORSOrigins() []string {
	raw := firstNonEmpty(
		os.Getenv("CORS_ORIGINS"),
		os.Getenv("ALLOWED_ORIGINS"),
		"http://localhost:3000",
	)
	return splitCSV(raw)
}

func loadTrustedProxies() []string {
	raw := strings.TrimSpace(os.Getenv("TRUSTED_PROXIES"))
	if raw == "" {
		raw = "127.0.0.1/8,::1/128,192.168.0.0/16,10.0.0.0/8,172.16.0.0/12,100.64.0.0/10"
	}
	// Strip surrounding quotes from Jenkins env files
	raw = strings.Trim(raw, "\"'")
	return splitCSV(raw)
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return strings.TrimSpace(v)
		}
	}
	return ""
}

func parseJWTExpiryHours() int {
	if v := os.Getenv("JWT_EXPIRY_HOURS"); v != "" {
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			return n
		}
	}
	// core-service style: ACCESS_TOKEN_EXPIRES_IN=168h
	if v := os.Getenv("ACCESS_TOKEN_EXPIRES_IN"); v != "" {
		v = strings.TrimSuffix(strings.ToLower(v), "h")
		if n, err := strconv.Atoi(v); err == nil && n > 0 {
			return n
		}
	}
	return 168
}
