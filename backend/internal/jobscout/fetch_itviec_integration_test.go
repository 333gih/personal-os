//go:build integration

package jobscout

import (
	"context"
	"io"
	"net/http"
	"strings"
	"testing"
)

func TestProbeITviecVariants(t *testing.T) {
	t.Parallel()
	ctx := context.Background()
	urls := []string{
		"https://itviec.com/viec-lam-it/java",
		"https://itviec.com/it-jobs/java",
		"https://itviec.com/viec-lam-it/java?page=1",
	}
	for _, u := range urls {
		body, status, err := fetchHTMLWithHeaders(ctx, u, itviecBrowserHeaders())
		if err != nil {
			t.Logf("%s err=%v", u, err)
			continue
		}
		t.Logf("%s status=%d len=%d jobs=%v cf=%v",
			u, status, len(body),
			strings.Contains(body, "/it-jobs/"),
			strings.Contains(body, "cf-challenge") || strings.Contains(body, "Just a moment"))
		if status != 200 {
			continue
		}
		if strings.Contains(body, "/it-jobs/") {
			jobs, _ := parseITviecListHTML(body, "java")
			t.Logf("  parsed=%d count=%d", len(jobs), parseITviecJobCount(body))
		}
	}
}

func fetchHTMLWithHeaders(ctx context.Context, url string, headers map[string]string) (string, int, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", 0, err
	}
	for k, v := range headers {
		req.Header.Set(k, v)
	}
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", 0, err
	}
	defer res.Body.Close()
	b, err := io.ReadAll(io.LimitReader(res.Body, 2<<20))
	if err != nil {
		return "", res.StatusCode, err
	}
	return string(b), res.StatusCode, nil
}

func itviecBrowserHeaders() map[string]string {
	return map[string]string{
		"User-Agent":                browserUserAgent,
		"Accept":                    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
		"Accept-Language":           "vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7",
		"Referer":                   "https://itviec.com/",
		"Sec-Fetch-Dest":            "document",
		"Sec-Fetch-Mode":            "navigate",
		"Sec-Fetch-Site":            "same-origin",
		"Sec-Fetch-User":            "?1",
		"Upgrade-Insecure-Requests": "1",
	}
}
