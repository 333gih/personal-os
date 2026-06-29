package jobscout

import (
	"testing"
)

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
