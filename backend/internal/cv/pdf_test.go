package cv

import (
	"strings"
	"testing"
)

func TestRenderPDF_UTF8Characters(t *testing.T) {
	doc := CVDocument{
		Headline: "Nguyen Khoa Minh Phuc — Software Engineer",
		Summary:  "Enterprise AEM/Spring Boot engineer.",
		Contact: Contact{
			Email:    "test@example.com",
			Location: "Ho Chi Minh City, Vietnam",
		},
		Skills: []string{"Java", "Spring Boot", "AEM"},
		Experience: []BulletItem{
			{
				Company: "FPT Software",
				Title:   "Software Engineer",
				Period:  "2025 — Present",
				Content: "FTP→XML→XSL→AEM workflow.\nSpring Boot 3 migration.",
			},
		},
	}

	data, err := renderPDF(doc)
	if err != nil {
		t.Fatalf("renderPDF: %v", err)
	}
	if len(data) < 1024 {
		t.Fatalf("pdf too small: %d bytes", len(data))
	}
	if !strings.HasPrefix(string(data[:5]), "%PDF-") {
		t.Fatalf("not a pdf header")
	}
}

func TestSplitHeadline(t *testing.T) {
	name, role := splitHeadline("Nguyen Khoa Minh Phuc — Software Engineer")
	if name != "Nguyen Khoa Minh Phuc" || role != "Software Engineer" {
		t.Fatalf("unexpected split: %q / %q", name, role)
	}
}

func TestSplitBullets(t *testing.T) {
	got := splitBullets("Line one\nLine two")
	if len(got) != 2 || got[0] != "Line one" || got[1] != "Line two" {
		t.Fatalf("unexpected bullets: %#v", got)
	}
}

func TestRenderPDF_SinglePage(t *testing.T) {
	doc := fullV5TestDocument()
	data, err := renderPDF(doc)
	if err != nil {
		t.Fatalf("renderPDF: %v", err)
	}
	if pages := pdfPageCount(data); pages != 1 {
		t.Fatalf("expected 1 page, got %d", pages)
	}
}

func TestRenderPDF_CanonicalIdealSinglePage(t *testing.T) {
	doc := CanonicalIdealCV()
	data, err := renderPDF(doc)
	if err != nil {
		t.Fatalf("renderPDF: %v", err)
	}
	if pages := pdfPageCount(data); pages != 1 {
		t.Fatalf("canonical ideal CV must fit 1 page, got %d pages", pages)
	}
}

func TestTrimDocumentForLayout_PreservesStructure(t *testing.T) {
	doc := CanonicalIdealCV()
	trimmed := trimDocumentForLayout(doc, trimHeavy)
	if len(trimmed.Experience) == 0 || len(trimmed.Projects) == 0 {
		t.Fatal("trim should keep experience and projects")
	}
	if trimmed.Summary == "" {
		t.Fatal("trim should keep summary")
	}
}

func fullV5TestDocument() CVDocument {
	return CVDocument{
		Headline: "Nguyen Khoa Minh Phuc — Software Engineer",
		Summary:  "Software Engineer specializing in Java, AEM, and Spring Boot, with expertise in scalable backend systems, API integrations, and performance optimization. Experienced in integrating AI tools and LLM-based capabilities into enterprise applications. Proficient in SOLID principles, design patterns, multithreading, cloud deployments, CI/CD, and Docker.",
		Contact: Contact{
			Email:    "phuckhoa81@gmail.com",
			Phone:    "+(84) 972495038",
			Location: "Ho Chi Minh City",
			LinkedIn: "linkedin.com",
			GitHub:   "github.com",
		},
		SkillGroups: []SkillGroup{
			{Category: "Backend & APIs", Items: []string{"Java (Spring Boot, AEM)", "Node.js (NestJS)", "Golang", "gRPC", "WebSocket"}},
			{Category: "Frontend", Items: []string{"ReactJS", "NextJS", "Thymeleaf", "HTL"}},
			{Category: "Database & Caching", Items: []string{"PostgreSQL", "MySQL", "Oracle", "MongoDB", "Redis"}},
			{Category: "Search Engine", Items: []string{"ElasticSearch", "Algolia"}},
			{Category: "AI & Tooling", Items: []string{"GitHub Copilot", "Cursor AI", "Claude AI", "ChatGPT (for code generation, review & test writing); experience integrating AI tools and LLM-based capabilities into delivery workflows"}},
			{Category: "Scalability & Performance", Items: []string{"Microservices", "Kafka", "RabbitMQ", "Distributed Systems"}},
			{Category: "Cloud", Items: []string{"Google Cloud", "AEM Cloud"}},
		},
		Education: []EducationItem{
			{School: "Ho Chi Minh Open University (OU)", Period: "Present", Content: "Pursuing a Bachelor's degree in Information Technology."},
			{School: "FPT Polytechnic College", Period: "Graduated", Content: "Graduated with a strong foundation in software development and engineering principles."},
		},
		Achievements: []AchievementItem{
			{Content: "Delivered and optimized large-scale backend systems handling millions of records with high performance and reliability."},
			{Content: "Designed and maintained scalable architectures across multiple services, ensuring stability under heavy load."},
		},
		Certificates: []CertificateItem{
			{Title: "CodeGym Certification", Issuer: "Obtained a technical certification in software development."},
			{Title: "Coursera Certifications", Issuer: "Completed multiple courses on software development and database management."},
			{Title: "Google Certifications", Issuer: "Acquired certifications in modern technologies and best practices."},
		},
		Experience: []BulletItem{
			{Title: "Software Engineer", Company: "FPT Software", Period: "2025 — Now", Content: "Develop, migrate, and customize Spring Boot services and AEM components, templates, and workflows for enterprise applications.\nDesign and implement scalable, high-performance Java microservices.\nApply SOLID principles, design patterns to ensure efficiency and maintainability.\nOptimize performance, caching (Redis, CDN, AEM Dispatcher).\nBuild and maintain RESTful APIs, GraphQL, and third-party integrations.\nWork with CI/CD, Docker, and cloud platforms (GCP).\nApplied AI-powered solutions with OpenAI API to improve product capabilities for the Canon Bundle Application."},
			{Title: "Middle Developer cum Backend Lead", Company: "DHA Corporation + Tini Group (Techheart)", Period: "2024 — 2025", Content: "Led backend development, optimizing and maintaining large-scale product systems.\nDesigned and implemented scalable APIs, CI/CD pipelines.\nCollaborated with Web and Mobile teams to resolve deployment challenges and enhance system performance.\nProvided mentorship and training for new developers.\nUsed AI tools (ChatGPT, Copilot) to generate boilerplate code and unit test templates, reducing repetitive work for the team.\nIntegrated third-party smart device APIs, including smart door locks and air conditioner systems, printer, into product development."},
			{Title: "Junior Backend Developer", Company: "Tech SaaS Cloud Innovations (Odisha, India)", Period: "2023 — 2024", Content: "Developed and maintained full-stack applications with seamless backend-frontend integration.\nCollaborated with stakeholders to translate business needs into technical solutions.\nDeployed and optimized applications on Ubuntu servers and Cloud Provider (AWS) for reliability and scalability.\nAuthored technical documentation to support development and maintenance."},
		},
		Projects: []BulletItem{
			{Title: "Canon Bundle Project (Nw3s) — Software Engineer", Company: "FPT Software", Period: "3/2025 — 10/2025", Content: "Migrated Spring Boot 2 to 3 and upgraded Java 7 to 11.\nIntegrated Spring Boot workflows with AEM and Content Fragment processing.\nDeveloped workflow portals and improved system maintainability.\nIntegrated PostgreSQL, GraphQL, and Elasticsearch into enterprise workflows.\nTech: Spring Boot, AEM, Oracle, PostgreSQL, GCP, ElasticSearch | Team Size: 135"},
			{Title: "Vietnam Airline Ticket Application — Software Engineer", Company: "FPT Software", Period: "9/2025 — 4/2026", Content: "Developed search features using Algolia Search.\nDesigned AEM components, templates, and servlets for search functionality.\nCollaborated with teams to synchronize data across the system.\nImproved maintainability and scalability of search implementations.\nTech: AEM, Algolia | Team Size: 150"},
			{Title: "Destu Project (Chugai) — Software Engineer", Company: "FPT Software", Period: "3/2026 — Present", Content: "Developed AEM components, templates, and servlets for enterprise solutions.\nCollaborated with Japanese clients to improve legacy workflows and requirements.\nSupported migration from AEM Enterprise to AEM Cloud.\nOptimized component reusability and maintainability.\nTech: AEM Cloud, Probo | Team Size: 50"},
		},
	}
}
