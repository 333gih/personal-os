package config

import (
	"os"
	"strings"
)

type NotificationConfig struct {
	Enabled          bool
	KafkaBrokers     []string
	KafkaTopic       string
	DefaultLocale    string
	FashAuthBaseURL  string
	FCMRegisterPath  string
	QuietStartHour   int
	QuietEndHour     int
}

func loadNotificationConfig() NotificationConfig {
	brokers := splitCSV(getEnv("KAFKA_BROKERS", getEnv("KAFKA_BROKER", "")))
	topic := getEnv("KAFKA_NOTIFICATION_TOPIC", getEnv("KAFKA_TOPIC", "notifications.requested"))
	enabled := len(brokers) > 0 && topic != ""
	quietStart, _ := parseIntEnv("NOTIFICATION_QUIET_START_HOUR", 22)
	quietEnd, _ := parseIntEnv("NOTIFICATION_QUIET_END_HOUR", 7)
	return NotificationConfig{
		Enabled:         enabled,
		KafkaBrokers:    brokers,
		KafkaTopic:      topic,
		DefaultLocale:   getEnv("NOTIFICATION_DEFAULT_LOCALE", "en"),
		FashAuthBaseURL: strings.TrimSuffix(getEnv("FASH_AUTH_BASE_URL", "https://api-auth.fashandcurious.com"), "/"),
		FCMRegisterPath: getEnv("FASH_AUTH_FCM_REGISTER_PATH", "/api/v1/auth/fcm/register"),
		QuietStartHour:  quietStart,
		QuietEndHour:    quietEnd,
	}
}

func parseIntEnv(key string, fallback int) (int, bool) {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return fallback, false
	}
	var v int
	for _, c := range raw {
		if c < '0' || c > '9' {
			return fallback, false
		}
		v = v*10 + int(c-'0')
	}
	return v, true
}
