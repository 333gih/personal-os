package cv

// CanonicalIdealCV is the authoritative one-page CV for the career owner account.
// Used when work_cv_document is missing or sparse (e.g. migration 028 created empty template blocks).
func CanonicalIdealCV() CVDocument {
	return CVDocument{
		Variant:  "ideal",
		Headline: "Nguyen Khoa Minh Phuc — Backend Software Engineer",
		Summary:  "Backend Software Engineer specializing in Java and Spring Boot for enterprise systems — BFF/API/batch tiers, AEM-Java integration, PostgreSQL, and Japanese client delivery. Strong in REST API design, batch processing, performance tuning, and CI/CD. Comfortable with TypeScript/React front-ends for integration; primary strength is backend system development.",
		Contact: Contact{
			Email:    "phuckhoa81@gmail.com",
			Phone:    "+(84) 972495038",
			Location: "Ho Chi Minh City, Vietnam",
			LinkedIn: "linkedin.com/in/nguyen-khoa-minh-phuc",
			GitHub:   "github.com/mphuc8671",
		},
		PrimaryStack:    []string{"Java", "Spring Boot", "Spring Batch", "AEM", "PostgreSQL"},
		YearsExperience: 3.5,
		SkillGroups: []SkillGroup{
			{Category: "Java & Spring Boot", Items: []string{"Java 17", "Spring Boot 3.4", "Spring Batch", "Spring Security", "Spring Data JPA", "OpenAPI", "Gradle/Maven"}},
			{Category: "Enterprise Systems", Items: []string{"REST/BFF layering", "API Gateway", "microservices", "gRPC", "batch jobs", "RabbitMQ/Kafka"}},
			{Category: "AEM & Java", Items: []string{"AEM Cloud / 6.5", "Sling/OSGi servlets", "workflows", "Content Fragments", "Author→Publish REST sync"}},
			{Category: "Data & DevOps", Items: []string{"PostgreSQL", "MySQL", "MongoDB", "Redis", "Elasticsearch", "Docker", "CI/CD", "GCP"}},
			{Category: "Frontend (supporting)", Items: []string{"TypeScript", "React", "Next.js — UI integration when needed"}},
		},
		Education: []EducationItem{
			{School: "Ho Chi Minh Open University (OU)", Period: "Present", Content: "Pursuing a Bachelor's degree in Information Technology."},
			{School: "FPT Polytechnic College", Period: "Graduated", Content: "Graduated with a strong foundation in software development and engineering principles."},
		},
		Achievements: []AchievementItem{
			{Content: "Authored Horserace layered system design: BFF, Domain REST API, Spring Batch settlement/report modules for JP betting platform."},
			{Content: "Built Java/Spring Boot services for high-volume workloads — PostgreSQL, Redis caching, CI/CD on GCP."},
			{Content: "Led Spring Boot 2→3 and Java 7→11 migrations; FTP/XML→AEM Content Fragment pipelines (Canon Bundle)."},
			{Content: "Delivered AEM Cloud Java components and REST sync workflows for pharmaceutical and airline enterprise clients."},
			{Content: "Designed scalable APIs and async processing for multi-tenant platforms; mentors junior backend developers."},
			{Content: "Integrated IoT device APIs and RabbitMQ async pipelines for Tini Coworking — dual Spring Boot Admin/User backends."},
		},
		Certificates: []CertificateItem{
			{Title: "CodeGym Certification", Issuer: "Technical certification in software development."},
			{Title: "Coursera Certifications", Issuer: "Software development and database management courses."},
			{Title: "Google Certifications", Issuer: "Modern cloud technologies and best practices."},
		},
		Experience: []BulletItem{
			{
				Title:   "Software Engineer",
				Company: "FPT Software",
				Period:  "2025 — Now",
				Content: "Backend-focused delivery for Japanese clients: Horserace betting platform system design, AEM + Spring Boot services.\nLayered BFF/API/batch architecture, REST/GraphQL APIs, performance optimization, CI/CD on GCP.",
			},
			{
				Title:   "Middle Developer cum Backend Lead",
				Company: "DHA Corporation + Tini Group (Techheart)",
				Period:  "2024 — 2025",
				Content: "Led Java Spring Boot backends for Tini Coworking and Tini Trade — dual Admin/User APIs, MongoDB, Docker VPS.\nIntegrated IoT devices (smart locks, AC, cameras, RFID parking); RabbitMQ async pipelines.\nBackend lead: API design, CI/CD, mentoring juniors.",
			},
			{
				Title:   "Junior Backend Developer",
				Company: "Tech SaaS Cloud Innovations (Odisha, India)",
				Period:  "2023 — 2024",
				Content: "Built full-stack features with Node.js and Next.js — backend–frontend integration, stakeholder collaboration.\nDeployed and optimized on Ubuntu/AWS; authored technical documentation.",
			},
		},
		Projects: []BulletItem{
			{
				Title:   "Horserace — JP Horse-Racing Betting Platform",
				Company: "FPT Software",
				Period:  "6/2026 — Present",
				Content: "System design: API Gateway → BFF → Domain REST API → PostgreSQL + Spring Batch tier.\nSpring Boot 3.4 BFF/REST/Batch modules — validation, i18n, pagination, SpringDoc OpenAPI.\nTech: Java, Spring Boot 3.4, Spring Batch, PostgreSQL, Gradle",
			},
			{
				Title:   "Destu Project (Chugai) — Software Engineer",
				Company: "FPT Software",
				Period:  "3/2026 — Present",
				Content: "AEM Cloud components, servlets, Author→Publish REST sync (JWT) for pharmaceutical content.\nTech: AEM Cloud, Java, Sling, Workflows | Team: 50",
			},
			{
				Title:   "Vietnam Airline Ticket Application — Software Engineer",
				Company: "FPT Software",
				Period:  "9/2025 — 4/2026",
				Content: "Algolia search on AEM publish; components, templates, servlets for global search.\nTech: AEM, Algolia, Java, HTL | Team: 150",
			},
			{
				Title:   "Canon Bundle Project (Nw3s) — Software Engineer",
				Company: "FPT Software",
				Period:  "3/2025 — 10/2025",
				Content: "Spring Boot 2→3, Java 7→11; FTP/SFTP→XML→AEM Content Fragment pipeline; GraphQL + Elasticsearch.\nTech: Spring Boot 3, AEM, GCP Cloud Run, PostgreSQL | Team: 135",
			},
			{
				Title:   "Tini Coworking — Space Management Platform",
				Company: "DHA Corporation + Tini Group (Techheart)",
				Period:  "6/2024 — 3/2025",
				Content: "Dual Java Spring Boot backends (Admin/User), MongoDB, Docker VPS; IoT gateway for locks, AC, cameras, RFID parking.\nRabbitMQ async workers for bookings and device commands; backend lead for API design and CI/CD.\nTech: Java, Spring Boot, MongoDB, RabbitMQ, Docker",
			},
			{
				Title:   "Tini Trade — Trading Platform",
				Company: "DHA Corporation + Tini Group (Techheart)",
				Period:  "4/2024 — 5/2024",
				Content: "Dual Java Spring Boot APIs — market listing, orders, portfolio on MongoDB; RabbitMQ settlement pipeline.\nTech: Java, Spring Boot, MongoDB, RabbitMQ, Docker",
			},
			{
				Title:   "Flow Diagram Builder — Full-stack SaaS Tool",
				Company: "Tech SaaS Cloud Innovations (Odisha, India)",
				Period:  "2022 — 2023",
				Content: "Drag-and-drop flow editor (React Flow) with Node.js REST API for diagram persistence.\nTech: Next.js, React Flow, Node.js, PostgreSQL",
			},
		},
	}
}

func documentIsSparse(doc CVDocument) bool {
	return len(doc.Experience) == 0 && len(doc.Projects) == 0
}
