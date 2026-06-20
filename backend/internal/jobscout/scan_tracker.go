package jobscout

import (
	"sync"
	"time"

	"github.com/google/uuid"
)

type userScanState struct {
	Status     string      `json:"status"`
	Error      string      `json:"error,omitempty"`
	Result     *ScanResult `json:"result,omitempty"`
	StartedAt  time.Time   `json:"started_at"`
	FinishedAt *time.Time  `json:"finished_at,omitempty"`
}

type scanTracker struct {
	mu    sync.Mutex
	runs  map[uuid.UUID]*userScanState
}

func newScanTracker() *scanTracker {
	return &scanTracker{runs: map[uuid.UUID]*userScanState{}}
}

func (t *scanTracker) start(userID uuid.UUID) (alreadyRunning bool) {
	t.mu.Lock()
	defer t.mu.Unlock()
	if run, ok := t.runs[userID]; ok && run.Status == "running" {
		return true
	}
	t.runs[userID] = &userScanState{
		Status:    "running",
		StartedAt: time.Now().UTC(),
	}
	return false
}

func (t *scanTracker) complete(userID uuid.UUID, result *ScanResult) {
	t.mu.Lock()
	defer t.mu.Unlock()
	now := time.Now().UTC()
	t.runs[userID] = &userScanState{
		Status:     "completed",
		Result:     result,
		StartedAt:  t.startedAtLocked(userID, now),
		FinishedAt: &now,
	}
}

func (t *scanTracker) fail(userID uuid.UUID, err error) {
	t.mu.Lock()
	defer t.mu.Unlock()
	now := time.Now().UTC()
	msg := "scan failed"
	if err != nil {
		msg = err.Error()
	}
	t.runs[userID] = &userScanState{
		Status:     "failed",
		Error:      msg,
		StartedAt:  t.startedAtLocked(userID, now),
		FinishedAt: &now,
	}
}

func (t *scanTracker) get(userID uuid.UUID) userScanState {
	t.mu.Lock()
	defer t.mu.Unlock()
	run, ok := t.runs[userID]
	if !ok || run == nil {
		return userScanState{Status: "idle"}
	}
	copy := *run
	return copy
}

func (t *scanTracker) startedAtLocked(userID uuid.UUID, fallback time.Time) time.Time {
	if run, ok := t.runs[userID]; ok && !run.StartedAt.IsZero() {
		return run.StartedAt
	}
	return fallback
}
