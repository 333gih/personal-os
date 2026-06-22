package config

import (
	"net"
	"net/url"
	"os"
	"strconv"
	"strings"
)

func loadDatabaseURL() string {
	// Prefer discrete POSTGRES_* vars when a password is configured — Jenkins and
	// core-service env files often carry a stale DATABASE_URL after password rotation.
	if postgresPasswordFromEnv() != "" {
		return buildDatabaseURLFromPostgresEnv()
	}
	if v := trimEnvQuotes(strings.TrimSpace(os.Getenv("DATABASE_URL"))); v != "" {
		return v
	}
	return buildDatabaseURLFromPostgresEnv()
}

func postgresPasswordFromEnv() string {
	return trimEnvQuotes(firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_PASSWORD"),
		os.Getenv("POSTGRES_PASSWORD"),
	))
}

func buildDatabaseURLFromPostgresEnv() string {
	host := trimEnvQuotes(firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_HOST"),
		os.Getenv("POSTGRES_HOST"),
		"localhost",
	))
	port := trimEnvQuotes(firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_PORT"),
		os.Getenv("POSTGRES_PORT"),
		"5432",
	))
	name := trimEnvQuotes(firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_NAME"),
		os.Getenv("POSTGRES_DB"),
		"personalos",
	))
	user := trimEnvQuotes(firstNonEmpty(
		os.Getenv("POSTGRES_DATABASE_USER"),
		os.Getenv("POSTGRES_USER"),
		"personalos",
	))
	pass := postgresPasswordFromEnv()
	if pass == "" {
		pass = "personalos"
	}
	sslMode := trimEnvQuotes(firstNonEmpty(os.Getenv("POSTGRES_SSL_MODE"), "disable"))

	u := &url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(user, pass),
		Host:   net.JoinHostPort(host, port),
		Path:   "/" + name,
	}
	q := u.Query()
	q.Set("sslmode", sslMode)
	u.RawQuery = q.Encode()
	return u.String()
}

func trimEnvQuotes(s string) string {
	return strings.Trim(s, "\"'")
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
	raw = trimEnvQuotes(raw)
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
