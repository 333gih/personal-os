package jobscout

import (
	"context"
	"io"
	"net/http"
	"strings"
	"testing"
)

func TestProbeITviecVariants(t *testing.T) {
	if testing.Short() {
		t.Skip("network")
	}
	t.Parallel()
	ctx := context.Background()
	urls := []string{
		"https://itviec.com/viec-lam-it/java",
		"https://itviec.com/it-jobs/java",
		"https://itviec.com/viec-lam-it/java?page=1",
		"https://m.itviec.com/viec-lam-it/java",
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
		"User-Agent":      browserUserAgent,
		"Accept":          "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8",
		"Accept-Language": "vi-VN,vi;q=0.9,en-US;q=0.8,en;q=0.7",
		"Accept-Encoding": "gzip, deflate, br",
		"Referer":         "https://itviec.com/",
		"Sec-Fetch-Dest":  "document",
		"Sec-Fetch-Mode":  "navigate",
		"Sec-Fetch-Site":  "same-origin",
		"Sec-Fetch-User":  "?1",
		"Upgrade-Insecure-Requests": "1",
	}
}

func TestParseITviecFixture(t *testing.T) {
	t.Parallel()
	html := `<a href="/it-jobs/senior-java-developer-fpt-software-123456">Senior Java Developer</a>
	<a href="/it-jobs/backend-engineer-spring-boot-vng-789012">Backend Engineer</a>
	<a href="/nha-tuyen-dung/fpt-software">FPT</a>
	</div>
	<p>139 việc làm Java tại Việt Nam</p>`
	jobs, err := parseITviecListHTML(html, "java")
	if err != nil {
		t.Fatal(err)
	}
	if len(jobs) != 2 {
		t.Fatalf("want 2 jobs got %d", len(jobs))
	}
	if jobs[0].Source != "itviec" || jobs[0].URL == "" {
		t.Fatalf("bad job: %+v", jobs[0])
	}
	if c := parseITviecJobCount(html); c != 139 {
		t.Fatalf("count=%d want 139", c)
	}
}

func TestSkillToITviecSlug(t *testing.T) {
	t.Parallel()
	cases := map[string]string{
		"Java":        "java",
		"Spring Boot": "spring-boot",
		"Node.js":     "node-js",
		"C#":          "c-sharp",
		"Golang":      "golang",
	}
	for in, want := range cases {
		if got := skillToITviecSlug(in); got != want {
			t.Errorf("%q => %q want %q", in, got, want)
		}
	}
}

func TestITviecSkillSlugs(t *testing.T) {
	t.Parallel()
	got := itviecSkillSlugs([]string{"Java", "java", "Spring Boot", ""})
	if len(got) != 2 {
		t.Fatalf("got %v", got)
	}
}


func TestSkillSlugExample(t *testing.T) {
	t.Parallel()
	if got := skillToITviecSlug("Spring Boot"); got != "spring-boot" {
		t.Fatalf("got %q", got)
	}
}
