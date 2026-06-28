package cv

// CanonicalIdealCV is the authoritative one-page CV for the career owner account.
// Used when work_cv_document is missing or sparse (e.g. migration 028 created empty template blocks).
func CanonicalIdealCV() CVDocument {
	return CVDocument{
		Variant:  "ideal",
		Headline: "Nguyen Khoa Minh Phuc — Software Engineer",
		Summary:  "Software Engineer with a backend focus on Java, Spring Boot, and enterprise system design — BFF/API/batch tiers, AEM-Java integration, PostgreSQL, and Japanese client delivery. Strong in REST API design, batch processing, performance tuning, and CI/CD. Comfortable collaborating on TypeScript/React front-ends; primary strength is backend delivery.",
		Contact: Contact{
			Email:    "mphuc8671@gmail.com",
			Phone:    "+84 972 495 038",
			Location: "Ho Chi Minh City, Vietnam",
			LinkedIn: "https://www.linkedin.com/in/minh-phuc-774110229/",
			GitHub:   "https://github.com/phuckhoa33",
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
				Content: "Authored layered system design: API Gateway → BFF → Domain REST API → PostgreSQL with dedicated Spring Batch tier for settlement and reporting.\nBuilt Spring Boot 3.4 BFF modules — request validation, JP/EN i18n, cursor pagination, and SpringDoc OpenAPI for partner integration.\nDesigned batch jobs for daily reconciliation and payout reports with idempotent execution and failure recovery.\nTech: Java 17, Spring Boot 3.4, Spring Batch, PostgreSQL, Gradle",
			},
			{
				Title:   "Destu Project (Chugai) — Software Engineer",
				Company: "FPT Software",
				Period:  "3/2026 — Present",
				Content: "Developed AEM Cloud components, OSGi servlets, and workflow models for pharmaceutical content delivery to JP market.\nImplemented Author→Publish REST sync with JWT auth for regulated content propagation across environments.\nCollaborated with 50-member squad on AEM Enterprise→Cloud migration and component standardization.\nTech: AEM Cloud, Java, Sling, Workflows",
			},
			{
				Title:   "Vietnam Airline Ticket Application — Software Engineer",
				Company: "FPT Software",
				Period:  "9/2025 — 4/2026",
				Content: "Integrated Algolia search on AEM publish tier — indexing, query tuning, and fallback for global ticket search.\nBuilt HTL components, editable templates, and Sling servlets for search results and filter facets.\nCoordinated with 150-member program on content model alignment and publish-tier performance.\nTech: AEM 6.5, Algolia, Java, HTL",
			},
			{
				Title:   "Canon Bundle Project (Nw3s) — Software Engineer",
				Company: "FPT Software",
				Period:  "3/2025 — 10/2025",
				Content: "Led Spring Boot 2→3 and Java 7→11 migration for product bundle workflows serving enterprise print catalog.\nBuilt FTP/SFTP→XML→XSL→AEM Content Fragment pipeline with validation, error queues, and audit logging.\nExposed GraphQL and Elasticsearch endpoints for bundle search; deployed services on GCP Cloud Run.\nTech: Spring Boot 3, AEM, GCP Cloud Run, PostgreSQL",
			},
			{
				Title:   "Tini Coworking — Space Management Platform",
				Company: "DHA Corporation + Tini Group (Techheart)",
				Period:  "6/2024 — 3/2025",
				Content: "Architected dual Spring Boot backends (Admin/User) on MongoDB with role-based API separation and Docker VPS deployment.\nIntegrated IoT gateway for smart locks, AC, cameras, and RFID parking — unified device command API.\nImplemented RabbitMQ workers for booking lifecycle, device events, and async notifications at scale.\nTech: Java, Spring Boot, MongoDB, RabbitMQ, Docker",
			},
			{
				Title:   "Tini Trade — Trading Platform",
				Company: "DHA Corporation + Tini Group (Techheart)",
				Period:  "4/2024 — 5/2024",
				Content: "Delivered dual Spring Boot APIs for market listings, order placement, and portfolio tracking on MongoDB.\nBuilt RabbitMQ settlement pipeline with retry policies and dead-letter handling for trade confirmation.\nContainerized services with Docker and documented REST contracts for mobile client integration.\nTech: Java, Spring Boot, MongoDB, RabbitMQ, Docker",
			},
			{
				Title:   "Flow Diagram Builder — Full-stack SaaS Tool",
				Company: "Tech SaaS Cloud Innovations (Odisha, India)",
				Period:  "2022 — 2023",
				Content: "Built drag-and-drop flow editor with React Flow and persisted diagram graphs via Node.js REST API.\nImplemented versioning, export (PNG/SVG), and collaborative editing hooks for multi-user workspaces.\nDeployed on Ubuntu/AWS with PostgreSQL persistence and CI pipeline for frontend/backend releases.\nTech: Next.js, React Flow, Node.js, PostgreSQL",
			},
		},
	}
}

func documentIsSparse(doc CVDocument) bool {
	return len(doc.Experience) == 0 && len(doc.Projects) == 0
}
