package jobscout

import "time"

type ScanResult struct {
	Found     int     `json:"found"`
	Matched   int     `json:"matched"`
	Stored    int     `json:"stored"`
	Updated   int     `json:"updated"`
	MinScore  float32 `json:"min_score"`
	ScannedAt time.Time `json:"scanned_at"`
	Sources   struct {
		Remotive int `json:"remotive"`
		RemoteOK int `json:"remoteok"`
		GitHub   int `json:"github"`
		ITviec   int `json:"itviec"`
		TopCV    int `json:"topcv"`
	} `json:"sources"`
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
