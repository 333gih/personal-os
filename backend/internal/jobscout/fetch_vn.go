package jobscout

import (
	"context"
	"fmt"
	"net/http"
	"regexp"
	"strings"
)

var (
	topcvJobLinkRe = regexp.MustCompile(`https://www\.topcv\.vn/viec-lam/[^/\s"]+/(\d+)\.html`)
	vnJobCountRe   = regexp.MustCompile(`(?i)(\d[\d.,]*)\s+vi.{1,4}c\s+l.{1,4}m`)
)

func fetchTopCV(ctx context.Context, focusSkills []string) ([]rawJob, error) {
	slugs := vnSkillSlugs(focusSkills)
	if len(slugs) == 0 {
		slugs = []string{"java"}
	}

	seen := map[string]bool{}
	var out []rawJob
	var lastErr error
	for _, slug := range slugs {
		jobs, err := fetchTopCVSkillPage(ctx, slug)
		if err != nil {
			lastErr = fmt.Errorf("topcv %s: %w", slug, err)
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

func fetchTopCVSkillPage(ctx context.Context, skillSlug string) ([]rawJob, error) {
	pageURL := "https://www.topcv.vn/tim-viec-lam-" + skillSlug
	body, status, err := fetchHTML(ctx, pageURL)
	if err != nil {
		return nil, err
	}
	if status != http.StatusOK {
		return nil, fmt.Errorf("http %d", status)
	}
	return parseTopCVListHTML(body, skillSlug)
}

func parseTopCVListHTML(html, skillSlug string) ([]rawJob, error) {
	matches := topcvJobLinkRe.FindAllStringSubmatch(html, -1)
	if len(matches) == 0 {
		return nil, fmt.Errorf("no job links in page")
	}

	seen := map[string]bool{}
	out := make([]rawJob, 0, len(matches))
	for _, m := range matches {
		full := strings.TrimSpace(m[0])
		id := strings.TrimSpace(m[1])
		if full == "" || id == "" || seen[id] {
			continue
		}
		seen[id] = true
		url := full
		if i := strings.Index(url, "?"); i >= 0 {
			url = url[:i]
		}
		title, company := topcvTitleCompanyFromContext(html, url)
		if title == "" {
			title = titleFromSlugPath(url, "viec-lam")
		}
		out = append(out, rawJob{
			Source:      "topcv",
			ExternalID:  id,
			Title:       title,
			Company:     company,
			Location:    "Vietnam",
			URL:         url,
			Description: fmt.Sprintf("TopCV listing for %s — %s", skillSlug, title),
			Skills:      []string{skillSlug},
		})
		if len(out) >= 40 {
			break
		}
	}
	return out, nil
}

func topcvTitleCompanyFromContext(html, url string) (title, company string) {
	idx := strings.Index(html, url)
	if idx < 0 {
		return "", ""
	}
	start := idx - 500
	if start < 0 {
		start = 0
	}
	end := idx + 200
	if end > len(html) {
		end = len(html)
	}
	window := html[start:idx]
	// Title is usually in a heading immediately before the URL.
	if h := strings.LastIndex(window, "### "); h >= 0 {
		line := window[h+4:]
		if nl := strings.Index(line, "\n"); nl >= 0 {
			title = strings.TrimSpace(line[:nl])
		}
	}
	if title == "" {
		if h := strings.LastIndex(window, ">"); h >= 0 && h < len(window)-1 {
			chunk := window[h+1:]
			if j := strings.Index(chunk, "<"); j > 0 {
				candidate := strings.TrimSpace(stripHTML(chunk[:j]))
				if len(candidate) > 5 && len(candidate) < 120 {
					title = candidate
				}
			}
		}
	}
	after := html[idx+len(url):]
	if nl := strings.Index(after, "\n"); nl >= 0 {
		company = strings.TrimSpace(stripHTML(after[:nl]))
	}
	return title, company
}

func stripHTML(s string) string {
	s = regexp.MustCompile(`<[^>]+>`).ReplaceAllString(s, " ")
	return strings.Join(strings.Fields(s), " ")
}

func parseTopCVJobCount(html string) int {
	return parseVNJobCount(html)
}

func parseVNJobCount(html string) int {
	if m := vnJobCountRe.FindStringSubmatch(html); len(m) >= 2 {
		n := strings.ReplaceAll(m[1], ".", "")
		n = strings.ReplaceAll(n, ",", "")
		var count int
		fmt.Sscanf(n, "%d", &count)
		return count
	}
	return 0
}

func titleFromSlugPath(url, segment string) string {
	parts := strings.Split(url, "/")
	for i, p := range parts {
		if p == segment && i+1 < len(parts) {
			slug := strings.TrimSuffix(parts[i+1], ".html")
			return humanizeSlug(slug)
		}
	}
	return ""
}

func humanizeSlug(slug string) string {
	words := strings.Split(slug, "-")
	for i, w := range words {
		if w == "" {
			continue
		}
		words[i] = strings.ToUpper(w[:1]) + w[1:]
	}
	return strings.Join(words, " ")
}

func vnSkillSlugs(skills []string) []string {
	return itviecSkillSlugs(skills)
}

func isVNJobBoardSource(source string) bool {
	switch source {
	case "itviec", "topcv", "vietnamworks":
		return true
	default:
		return false
	}
}
