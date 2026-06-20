package main

import (
	"context"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"github.com/personal-os/backend/internal/ai"
	"github.com/personal-os/backend/internal/auth"
	"github.com/personal-os/backend/internal/cv"
	"github.com/personal-os/backend/internal/dashboard"
	"github.com/personal-os/backend/internal/embedding"
	"github.com/personal-os/backend/internal/entity"
	"github.com/personal-os/backend/internal/infrastructure/qdrant"
	"github.com/personal-os/backend/internal/relation"
	"github.com/personal-os/backend/internal/readingprogress"
	"github.com/personal-os/backend/internal/reminder"
	"github.com/personal-os/backend/internal/search"
	"github.com/personal-os/backend/internal/storage"
	"github.com/personal-os/backend/pkg/config"
	"github.com/personal-os/backend/pkg/database"
)

func main() {
	_ = godotenv.Load()

	cfg := config.Load()
	if cfg.AppEnv == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	db, err := database.Connect(cfg.DatabaseURL, cfg.AppEnv)
	if err != nil {
		log.Fatalf("database: %v", err)
	}

	authSvc := auth.NewService(db, cfg.JWTSecret, cfg.JWTIssuer, cfg.JWTExpiry, auth.FashAuthSettings{
		Enabled:   cfg.FashAuth.Enabled,
		JWTSecret: cfg.FashAuth.JWTSecret,
		JWTIssuer: cfg.FashAuth.JWTIssuer,
	})
	if !authSvc.UsesFashAuth() {
		if err := authSvc.EnsureDefaultUser(cfg.DefaultUserEmail, cfg.DefaultUserPass, "Admin"); err != nil {
			log.Fatalf("seed user: %v", err)
		}
	} else {
		log.Printf("auth: fash-auth-service JWT validation enabled (issuer=%s)", cfg.FashAuth.JWTIssuer)
	}

	aiSvc := ai.NewService(db, ai.ClientConfig{
		BaseURL:        cfg.OpenAIBaseURL,
		APIKey:         cfg.OpenAIAPIKey,
		ChatModel:      cfg.OpenAIModel,
		EmbeddingModel: cfg.OpenAIEmbeddingModel,
		SiteURL:        cfg.OpenRouterSiteURL,
		AppName:        cfg.OpenRouterAppName,
	})
	if !aiSvc.Configured() {
		log.Printf("ai: analyze/embeddings will use fallbacks until OPENROUTER_API_KEY is set")
	}

	qdrantClient := qdrant.NewClient(
		cfg.AI.QdrantURL,
		cfg.AI.QdrantAPIKey,
		cfg.AI.QdrantCollection,
		cfg.EmbeddingDim,
		cfg.AI.QdrantEnabled,
	)
	embedSvc := embedding.NewService(db, aiSvc, qdrantClient, embedding.WorkerConfig{
		Enabled:     cfg.AI.EmbeddingWorkerEnabled,
		Interval:    cfg.AI.EmbeddingWorkerInterval,
		MaxAttempts: cfg.AI.EmbeddingMaxAttempts,
		VectorSize:  cfg.EmbeddingDim,
	})

	entitySvc := entity.NewService(db, aiSvc, embedSvc)
	relationSvc := relation.NewService(db)
	searchSvc := search.NewService(db, aiSvc, qdrantClient)
	reminderSvc := reminder.NewService(db)

	go embedSvc.StartWorker(context.Background())

	storageSvc, err := storage.NewService(db, cfg.Storage)
	if err != nil {
		log.Fatalf("storage: %v", err)
	}
	if cfg.Storage.IsRemote() && !storageSvc.Enabled() {
		log.Printf("storage: S3/SeaweedFS configured but bucket %q unavailable — file uploads disabled (check S3_* credentials, bucket, and seaweedfs-net)", cfg.Storage.Bucket)
	} else if !storageSvc.Enabled() {
		log.Printf("storage: remote object storage disabled (set STORAGE_PROVIDER=seaweedfs + S3_* env)")
	}

	r := gin.New()
	r.Use(gin.Logger(), gin.Recovery())
	if err := r.SetTrustedProxies(cfg.TrustedProxies); err != nil {
		log.Printf("trusted proxies: %v", err)
	}

	r.Use(corsMiddleware(cfg.CORSOrigins))

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "personal-os",
			"ai":      aiSvc.Status(),
		})
	})

	api := r.Group("/api/v1")
	authHandler := auth.NewHandler(authSvc)
	authRoutes := api.Group("/auth")
	if !authSvc.UsesFashAuth() {
		authHandler.RegisterRoutes(authRoutes)
	} else {
		authHandler.RegisterProfileRoutes(authRoutes)
	}

	protected := api.Group("")
	protected.Use(auth.Middleware(authSvc))

	entityHandler := entity.NewHandler(entitySvc)
	entityHandler.RegisterRoutes(protected.Group("/entities"))

	relationHandler := relation.NewHandler(relationSvc)
	relationHandler.RegisterRoutes(protected.Group("/relationships"))

	searchHandler := search.NewHandler(searchSvc)
	searchHandler.RegisterRoutes(protected.Group("/search"))

	aiHandler := ai.NewHandler(aiSvc)
	aiHandler.RegisterRoutes(protected.Group("/ai"))

	readingProgressSvc := readingprogress.NewService(db, embedSvc)
	readingProgressHandler := readingprogress.NewHandler(readingProgressSvc)
	readingProgressHandler.RegisterRoutes(protected.Group("/reading-progress"))

	reminderHandler := reminder.NewHandler(reminderSvc)
	reminderHandler.RegisterRoutes(protected.Group("/reminders"))

	storageHandler := storage.NewHandler(storageSvc, entitySvc)
	storageHandler.RegisterRoutes(protected.Group("/files"))

	dashboardHandler := dashboard.NewHandler(entitySvc, reminderSvc)
	dashboardHandler.RegisterRoutes(protected.Group("/dashboard"))

	cvSvc := cv.NewService(db, aiSvc, storageSvc)
	cvHandler := cv.NewHandler(cvSvc)
	cvHandler.RegisterRoutes(protected.Group("/cv"))

	addr := ":" + cfg.AppPort
	log.Printf("personal-os API listening on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatal(err)
	}
}

func corsMiddleware(origins []string) gin.HandlerFunc {
	allowed := map[string]bool{}
	for _, o := range origins {
		allowed[o] = true
	}
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if allowed[origin] || len(origins) == 0 {
			c.Header("Access-Control-Allow-Origin", origin)
		}
		c.Header("Access-Control-Allow-Methods", "GET,POST,PUT,DELETE,OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Authorization,Content-Type")
		c.Header("Access-Control-Max-Age", "86400")
		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}
