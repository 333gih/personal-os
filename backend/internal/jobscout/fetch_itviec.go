package jobscout

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"regexp"
	"strings"
)

const browserUserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

var (
	itviecJobLinkRe = regexp.MustCompile(`href="(?:https://itviec\.com)?(/(?:it-jobs|viec-lam)/[^"#?\s]+)"`)
)

func fetchITviec(ctx context.Context, focusSkills []string) ([]rawJob, error) {
	slugs := itviecSkillSlugs(focusSkills)
	if len(slugs) == 0 {
		slugs = []string{"java"}
	}

	seen := map[string]bool{}
	var out []rawJob
	var lastErr error
	for _, slug := range slugs {
		jobs, err := fetchITviecSkillPage(ctx, slug)
		if err != nil {
			lastErr = fmt.Errorf("itviec %s: %w", slug, err)
			continue
		}
		for _, j := range jobs {
			key := j.ExternalID
			if key == "" {
				key = j.URL
			}
			if seen[key] {
				continue
			}
			seen[key] = true
			out = append(out, j)
		}
	}
	if len(out) == 0 && lastErr != nil {
		return nil, lastErr
	}
	return out, nil
}

func fetchITviecSkillPage(ctx context.Context, skillSlug string) ([]rawJob, error) {
	urls := []string{
		"https://itviec.com/viec-lam-it/" + skillSlug,
		"https://itviec.com/it-jobs/" + skillSlug,
	}
	var lastErr error
	for _, pageURL := range urls {
		body, status, err := fetchHTML(ctx, pageURL)
		if err != nil {
			lastErr = err
			continue
		}
		if status != http.StatusOK {
			lastErr = fmt.Errorf("http %d", status)
			continue
		}
		if strings.Contains(body, "Just a moment") || strings.Contains(body, "cf-challenge") {
			lastErr = fmt.Errorf("blocked by cloudflare")
			continue
		}
		jobs, err := parseITviecListHTML(body, skillSlug)
		if err != nil {
			lastErr = err
			continue
		}
		return jobs, nil
	}
	if lastErr == nil {
		lastErr = fmt.Errorf("no listings")
	}
	return nil, lastErr
}

func itviecSkillSlugs(skills []string) []string {
	seen := map[string]bool{}
	var out []string
	add := func(slug string) {
		slug = strings.Trim(slug, "/")
		if slug == "" || seen[slug] {
			return
		}
		seen[slug] = true
		out = append(out, slug)
	}
	for _, skill := range skills {
		add(skillToITviecSlug(skill))
	}
	return out
}

func skillToITviecSlug(skill string) string {
	skill = strings.TrimSpace(skill)
	if skill == "" {
		return ""
	}
	lower := strings.ToLower(skill)
	repl := strings.NewReplacer(
		".", "-", "+", "-plus", "#", "-sharp", " ", "-", "_", "-",
	)
	slug := repl.Replace(lower)
	for strings.Contains(slug, "--") {
		slug = strings.ReplaceAll(slug, "--", "-")
	}
	return strings.Trim(slug, "-")
}

func parseITviecListHTML(html, skillSlug string) ([]rawJob, error) {
	matches := itviecJobLinkRe.FindAllStringSubmatch(html, -1)
	if len(matches) == 0 {
		return nil, fmt.Errorf("no job links in page")
	}

	type item struct {
		path  string
		title string
	}
	ordered := make([]item, 0, len(matches))
	seenPath := map[string]bool{}
	for _, m := range matches {
		path := strings.TrimSpace(m[1])
		if path == "" || seenPath[path] {
			continue
		}
		if strings.Contains(path, "/nha-tuyen-dung/") || strings.Contains(path, "/companies/") {
			continue
		}
		seenPath[path] = true
		ordered = append(ordered, item{path: path})
	}

	out := make([]rawJob, 0, len(ordered))
	for _, it := range ordered {
		slug := strings.TrimPrefix(strings.TrimPrefix(it.path, "/it-jobs/"), "/viec-lam/")
		if slug == "" || slug == skillSlug {
			continue
		}
		title := itviecTitleFromSlug(slug)
		if parsedTitle := titleFromSlugPath("https://itviec.com/it-jobs/"+slug, "it-jobs"); parsedTitle != "" {
			title = parsedTitle
		}
		url := "https://itviec.com" + it.path
		skills := []string{skillSlug}
		for _, extra := range extractInlineSkills(html, slug) {
			skills = append(skills, extra)
		}
		out = append(out, rawJob{
			Source:      "itviec",
			ExternalID:  slug,
			Title:       title,
			Company:     itviecCompanyFromSlug(slug),
			Location:    "Vietnam",
			URL:         url,
			Description: fmt.Sprintf("ITviec listing for %s — %s", skillSlug, title),
			Skills:      dedupeStrings(skills),
		})
		if len(out) >= 40 {
			break
		}
	}
	return out, nil
}

func itviecTitleFromSlug(slug string) string {
	parts := strings.Split(slug, "-")
	if len(parts) < 2 {
		return strings.ReplaceAll(slug, "-", " ")
	}
	// drop trailing numeric job id if present
	if n := len(parts); n > 1 {
		last := parts[n-1]
		if len(last) >= 3 && len(last) <= 6 && isDigits(last) {
			parts = parts[:n-1]
		}
	}
	// drop company slug tail (heuristic: last segment if short brand)
	if len(parts) > 4 {
		parts = parts[:len(parts)-1]
	}
	title := strings.Join(parts, " ")
	return strings.Title(title)
}

func itviecCompanyFromSlug(slug string) string {
	parts := strings.Split(slug, "-")
	if len(parts) < 2 {
		return ""
	}
	if n := len(parts); n > 1 && isDigits(parts[n-1]) {
		parts = parts[:n-1]
	}
	if len(parts) == 0 {
		return ""
	}
	brand := parts[len(parts)-1]
	return strings.Title(strings.ReplaceAll(brand, "-", " "))
}

func isDigits(s string) bool {
	for _, r := range s {
		if r < '0' || r > '9' {
			return false
		}
	}
	return s != ""
}

func extractInlineSkills(html, slug string) []string {
	idx := strings.Index(html, slug)
	if idx < 0 {
		return nil
	}
	start := idx - 200
	if start < 0 {
		start = 0
	}
	end := idx + 800
	if end > len(html) {
		end = len(html)
	}
	window := html[start:end]
	var skills []string
	for _, token := range []string{"Java", "Spring Boot", "Spring", "Golang", "NodeJS", "TypeScript", "React", "AWS", "PostgreSQL"} {
		if strings.Contains(window, token) {
			skills = append(skills, token)
		}
	}
	return skills
}

func fetchHTML(ctx context.Context, url string) (string, int, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", 0, err
	}
	for k, v := range browserHeaders() {
		req.Header.Set(k, v)
	}
	if strings.Contains(url, "topcv.vn") {
		req.Header.Set("Referer", "https://www.topcv.vn/")
	}
	if cookie := strings.TrimSpace(os.Getenv("ITVIEC_COOKIE")); cookie != "" && strings.Contains(url, "itviec.com") {
		req.Header.Set("Cookie", cookie)
	}
	if cookie := strings.TrimSpace(os.Getenv("TOPCV_COOKIE")); cookie != "" && strings.Contains(url, "topcv.vn") {
		req.Header.Set("Cookie", cookie)
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

func browserHeaders() map[string]string {
	return map[string]string{
		"User-Agent":                browserUserAgent,
		"Accept":                    "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
		"Accept-Language":           "vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7",
		"Referer":                   "https://itviec.com/",
		"Sec-Fetch-Dest":            "document",
		"Sec-Fetch-Mode":            "navigate",
		"Sec-Fetch-Site":            "none",
		"Sec-Fetch-User":            "?1",
		"Upgrade-Insecure-Requests": "1",
	}
}

func parseITviecJobCount(html string) int {
	return parseVNJobCount(html)
}
