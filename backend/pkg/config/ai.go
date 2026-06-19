package config

import (
	"strconv"
	"time"
)

type AIConfig struct {
	QdrantEnabled          bool
	QdrantURL              string
	QdrantAPIKey           string
	QdrantCollection       string
	EmbeddingWorkerEnabled bool
	EmbeddingWorkerInterval time.Duration
	EmbeddingMaxAttempts   int
}

func loadAIConfig() AIConfig {
	intervalSec, _ := strconv.Atoi(getEnv("EMBEDDING_WORKER_INTERVAL_SEC", "5"))
	maxAttempts, _ := strconv.Atoi(getEnv("EMBEDDING_MAX_ATTEMPTS", "5"))

	return AIConfig{
		QdrantEnabled:           getEnv("QDRANT_ENABLED", "false") == "true",
		QdrantURL:               getEnv("QDRANT_URL", "http://localhost:6333"),
		QdrantAPIKey:            getEnv("QDRANT_API_KEY", ""),
		QdrantCollection:        getEnv("QDRANT_COLLECTION", "personal_context"),
		EmbeddingWorkerEnabled:  getEnv("EMBEDDING_WORKER_ENABLED", "true") == "true",
		EmbeddingWorkerInterval: time.Duration(intervalSec) * time.Second,
		EmbeddingMaxAttempts:    maxAttempts,
	}
}
