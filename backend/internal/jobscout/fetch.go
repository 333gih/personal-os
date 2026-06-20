package jobscout

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const (
	remotiveAPI = "https://remotive.com/api/remote-jobs?category=software-dev"
	githubAPI   = "https://api.github.com/search/issues"
)

func fetchRemotive(ctx context.Context) ([]rawJob, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, remotiveAPI, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "PersonalOS-JobScout/1.0")

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(res.Body, 512))
		return nil, fmt.Errorf("remotive api %d: %s", res.StatusCode, strings.TrimSpace(string(body)))
	}

	var payload struct {
		Jobs []struct {
			ID          int    `json:"id"`
			Title       string `json:"title"`
			CompanyName string `json:"company_name"`
			Candidate   string `json:"candidate_required_location"`
			URL         string `json:"url"`
			Description string `json:"description"`
			Tags        string `json:"tags"`
			Publication string `json:"publication_date"`
		} `json:"jobs"`
	}
	if err := json.NewDecoder(res.Body).Decode(&payload); err != nil {
		return nil, err
	}

	out := make([]rawJob, 0, len(payload.Jobs))
	for _, j := range payload.Jobs {
		skills := splitTags(j.Tags)
		var posted *time.Time
		if j.Publication != "" {
			if t, err := time.Parse("2006-01-02", j.Publication); err == nil {
				posted = &t
			}
		}
		out = append(out, rawJob{
			Source:      "remotive",
			ExternalID:  fmt.Sprintf("%d", j.ID),
			Title:       strings.TrimSpace(j.Title),
			Company:     strings.TrimSpace(j.CompanyName),
			Location:    strings.TrimSpace(j.Candidate),
			URL:         strings.TrimSpace(j.URL),
			Description: trimDesc(j.Description, 4000),
			Skills:      skills,
			PostedAt:    posted,
		})
	}
	return out, nil
}

func fetchGitHub(ctx context.Context, skills []string, token string) ([]rawJob, error) {
	queryParts := []string{
		`is:issue`, `is:open`,
		`label:"help wanted"`,
	}
	for _, skill := range skills {
		skill = strings.TrimSpace(skill)
		if skill == "" {
			continue
		}
		if len(queryParts) >= 8 {
			break
		}
		queryParts = append(queryParts, quoteToken(skill))
	}
	q := strings.Join(queryParts, " ")

	u, _ := url.Parse(githubAPI)
	u.RawQuery = url.Values{
		"q":        {q},
		"sort":     {"updated"},
		"order":    {"desc"},
		"per_page": {"30"},
	}.Encode()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u.String(), nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "application/vnd.github+json")
	req.Header.Set("User-Agent", "PersonalOS-JobScout/1.0")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	if res.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(io.LimitReader(res.Body, 512))
		return nil, fmt.Errorf("github search %d: %s", res.StatusCode, strings.TrimSpace(string(body)))
	}

	var payload struct {
		Items []struct {
			ID        int64  `json:"id"`
			Title     string `json:"title"`
			HTMLURL   string `json:"html_url"`
			Body      string `json:"body"`
			CreatedAt time.Time `json:"created_at"`
			User      struct {
				Login string `json:"login"`
			} `json:"user"`
		} `json:"items"`
	}
	if err := json.NewDecoder(res.Body).Decode(&payload); err != nil {
		return nil, err
	}

	out := make([]rawJob, 0, len(payload.Items))
	for _, item := range payload.Items {
		title := strings.TrimSpace(item.Title)
		if title == "" {
			continue
		}
		created := item.CreatedAt
		out = append(out, rawJob{
			Source:      "github",
			ExternalID:  fmt.Sprintf("%d", item.ID),
			Title:       title,
			Company:     item.User.Login,
			Location:    "Remote / GitHub",
			URL:         item.HTMLURL,
			Description: trimDesc(item.Body, 2000),
			PostedAt:    &created,
		})
	}
	return out, nil
}

func splitTags(raw string) []string {
	raw = strings.ReplaceAll(raw, ";", ",")
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, p := range parts {
		p = strings.TrimSpace(p)
		if p != "" {
			out = append(out, p)
		}
	}
	return out
}

func quoteToken(s string) string {
	if strings.Contains(s, " ") {
		return `"` + s + `"`
	}
	return s
}

func trimDesc(s string, max int) string {
	s = strings.TrimSpace(s)
	if len(s) <= max {
		return s
	}
	return s[:max] + "…"
}
