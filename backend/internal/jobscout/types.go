package jobscout

import "time"

type ScanResult struct {
	Found   int `json:"found"`
	Stored  int `json:"stored"`
	Updated int `json:"updated"`
	Sources struct {
		Remotive int `json:"remotive"`
		GitHub   int `json:"github"`
	} `json:"sources"`
	ScannedAt time.Time `json:"scanned_at"`
}

type UpdateStatusRequest struct {
	Status string `json:"status" binding:"required,oneof=open applied dismissed"`
}

type rawJob struct {
	Source      string
	ExternalID  string
	Title       string
	Company     string
	Location    string
	URL         string
	Description string
	Skills      []string
	PostedAt    *time.Time
}
