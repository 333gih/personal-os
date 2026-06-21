package studylearning

import (
	"context"
	"log"
	"time"
)

type Worker struct {
	svc      *Service
	interval time.Duration
}

func NewWorker(svc *Service, interval time.Duration) *Worker {
	if interval <= 0 {
		interval = 2 * time.Minute
	}
	return &Worker{svc: svc, interval: interval}
}

func (w *Worker) Start(ctx context.Context) {
	log.Printf("studylearning worker: interval=%s", w.interval)
	ticker := time.NewTicker(w.interval)
	defer ticker.Stop()

	w.tick(ctx)

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			w.tick(ctx)
		}
	}
}

func (w *Worker) tick(ctx context.Context) {
	if err := w.svc.DispatchDueReminders(ctx); err != nil {
		log.Printf("studylearning: dispatch reminders: %v", err)
	}
	if err := w.svc.ProcessPendingJobs(ctx, 2); err != nil {
		log.Printf("studylearning: process jobs: %v", err)
	}
	if w.shouldEnsureDaily() {
		if err := w.svc.EnsureAllUsersTodayReminders(); err != nil {
			log.Printf("studylearning: ensure today: %v", err)
		}
	}
}

var lastDailyEnsure time.Time

func (w *Worker) shouldEnsureDaily() bool {
	loc, _ := time.LoadLocation("Asia/Ho_Chi_Minh")
	now := time.Now().In(loc)
	if now.Hour() != 6 {
		return false
	}
	if time.Since(lastDailyEnsure) < 50*time.Minute {
		return false
	}
	lastDailyEnsure = now
	return true
}
