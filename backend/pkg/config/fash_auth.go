package config

import "os"

type FashAuthConfig struct {
	Enabled   bool
	JWTSecret string
	JWTIssuer string
}

func loadFashAuthConfig() FashAuthConfig {
	secret := firstNonEmpty(
		os.Getenv("FASH_AUTH_JWT_SECRET"),
		os.Getenv("ACCESS_TOKEN_SECRET"),
	)
	issuer := firstNonEmpty(
		os.Getenv("FASH_AUTH_JWT_ISSUER"),
		os.Getenv("JWT_ISSUER"),
		"fash-auth-service-app-dev",
	)

	mode := os.Getenv("AUTH_MODE")
	enabled := mode == "fash" || (mode != "local" && secret != "")

	return FashAuthConfig{
		Enabled:   enabled,
		JWTSecret: secret,
		JWTIssuer: issuer,
	}
}
